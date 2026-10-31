import http.server
import json
import subprocess
import os
import hashlib
import threading
import uuid
import time
import logging
import ipaddress
import re

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

CONV_ID_REGEX = re.compile(r"^[a-zA-Z0-9_][a-zA-Z0-9_-]*$")


def _is_valid_conv_id(conv_id):
    """Check if conv_id matches expected alphanumeric/hyphen/underscore format.

    Ensures conv_id cannot start with a dash (flag injection) or contain control characters / null bytes.
    """
    if not isinstance(conv_id, str):
        return False
    return bool(CONV_ID_REGEX.match(conv_id))


def _sanitize_prompt(prompt):
    """Sanitize prompt text by stripping null bytes that would cause subprocess failures."""
    if not isinstance(prompt, str):
        return ""
    return prompt.replace("\x00", "")

# Thread-safe in-memory cache mapping history hashes to conversation IDs
cache_lock = threading.Lock()
history_to_conv_id = {}

# Allowed models for Antigravity bridge mapping
ALLOWED_MODELS = frozenset({"flash_lite", "flash", "pro"})
# Recognized standard OpenAI chat completion roles
ALLOWED_ROLES = frozenset({"user", "assistant", "system", "developer", "tool", "function"})

# SECURITY: This bridge has no authentication. Any client that can reach it can
# drive the local `agentapi` agent with arbitrary prompts, executing with this
# user's privileges and environment. It must therefore only ever listen on
# loopback.
DEFAULT_HOST = "127.0.0.1"


def _is_loopback(host):
    """Check whether a host string resolves to a loopback address.

    SECURITY: Unauthenticated bridges must only listen on loopback interfaces.
    """
    if not host or not isinstance(host, str):
        return False
    host_clean = host.strip().lower()
    if host_clean in {"localhost", "localhost.localdomain"}:
        return True
    try:
        ip = ipaddress.ip_address(host_clean)
        return ip.is_loopback
    except ValueError:
        return False

# SECURITY: Unauthenticated callers must not be able to make the server buffer
# an unbounded body in memory (single-request memory exhaustion).
MAX_CONTENT_LENGTH = 8 * 1024 * 1024


def _extract_block_text(block):
    """Extract text from a single OpenAI content block.

    Supports string blocks directly, or text dict blocks ({"type": "text", "text": ...}).
    Returns an empty string for unsupported block structures.
    """
    if isinstance(block, str):
        return block
    if isinstance(block, dict) and block.get("type") == "text":
        text = block.get("text")
        if isinstance(text, str):
            return text
    return ""


def _extract_text(content):
    """Flatten OpenAI message content into a plain string.

    Accepts a plain string, or the structured content-block list form
    ([{"type": "text", "text": ...}]). Anything else yields "" rather than a
    Python repr, which would splice dict/list syntax into the prompt.
    Sanitizes null bytes to prevent subprocess execution failures.
    """
    if isinstance(content, str):
        return content.replace("\x00", "")
    if not isinstance(content, list):
        return ""
    text = "".join(_extract_block_text(b) for b in content)
    return text.replace("\x00", "")


def _normalize_message(raw_role, raw_content):
    """Constructs a normalized message dictionary with deterministic key ordering.

    Ensures both input messages and assistant responses use the exact same key order
    ('role' followed by 'content'), making json.dumps without key-sorting safe and fast.
    """
    if isinstance(raw_role, str):
        role_lower = raw_role.lower()
        role = role_lower if role_lower in ALLOWED_ROLES else "user"
    else:
        role = "user"
    return {"role": role, "content": _extract_text(raw_content)}


class OpenAIBridgeHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Redirect http.server logs to python logging
        logging.info("%s - - %s" % (self.address_string(), format % args))

    def send_json(self, status_code, data):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def send_error_response(self, status_code, message):
        self.send_json(status_code, {
            "error": {
                "message": message,
                "type": "invalid_request_error",
                "code": None
            }
        })

    def do_GET(self):
        path = self.path.rstrip("/")
        if path == "/v1/models":
            self.handle_models()
        else:
            self.send_error_response(404, f"Not Found: {self.path}")

    def do_POST(self):
        path = self.path.rstrip("/")
        if path == "/v1/chat/completions":
            self.handle_chat_completions()
        elif path == "/v1/completions":
            self.handle_completions()
        else:
            self.send_error_response(404, f"Not Found: {self.path}")

    def handle_models(self):
        models_data = {
            "object": "list",
            "data": [
                {"id": "flash_lite", "object": "model", "created": 1677652288, "owned_by": "antigravity"},
                {"id": "flash", "object": "model", "created": 1677652288, "owned_by": "antigravity"},
                {"id": "pro", "object": "model", "created": 1677652288, "owned_by": "antigravity"}
            ]
        }
        self.send_json(200, models_data)

    def read_body(self):
        """Read the request body, enforcing a maximum size.

        Returns the decoded body, or None after sending an error response.
        SECURITY: rejecting oversized requests up front prevents an unauthenticated
        caller from forcing an unbounded allocation via Content-Length.
        """
        try:
            content_length = int(self.headers.get("Content-Length", 0))
        except (TypeError, ValueError):
            self.send_error_response(400, "Invalid Content-Length header")
            return None
        if content_length == 0:
            self.send_error_response(400, "Empty request body")
            return None
        if content_length > MAX_CONTENT_LENGTH:
            self.send_error_response(413, "Request body too large")
            return None
        return self.rfile.read(content_length)

    def handle_completions(self):
        body = self.read_body()
        if body is None:
            return
        try:
            req_data = json.loads(body.decode("utf-8"))
        except Exception as e:
            self.send_error_response(400, f"Invalid JSON: {str(e)}")
            return

        prompt = req_data.get("prompt", "")
        if isinstance(prompt, list):
            prompt = "\n".join(prompt)
        
        # Convert completion prompt to messages format
        messages = [{"role": "user", "content": prompt}]
        model = req_data.get("model", "flash_lite")
        self.process_completions(messages, model, is_chat=False)

    def handle_chat_completions(self):
        body = self.read_body()
        if body is None:
            return
        try:
            req_data = json.loads(body.decode("utf-8"))
        except Exception as e:
            self.send_error_response(400, f"Invalid JSON: {str(e)}")
            return

        messages = req_data.get("messages")
        if not messages or not isinstance(messages, list):
            self.send_error_response(400, "Field 'messages' must be a non-empty array")
            return

        model = req_data.get("model", "flash_lite")
        self.process_completions(messages, model, is_chat=True)

    def process_completions(self, messages, model, is_chat=True):
        # Map models to antigravity model options: flash_lite, flash, pro
        if not isinstance(model, str) or model not in ALLOWED_MODELS:
            logging.warning("Requested model %r not recognized. Falling back to 'flash_lite'.", model)
            model = "flash_lite"

        if not messages:
            self.send_error_response(400, "No messages provided")
            return

        # Normalize message roles to standard allowed roles upfront so cache
        # hashing and prompt construction are consistent.
        #
        # Non-dict entries are dropped, so the "current" message below is the
        # last *usable* one rather than necessarily the last one supplied.
        normalized_messages = []
        for msg in messages:
            if not isinstance(msg, dict):
                continue
            normalized_messages.append(_normalize_message(msg.get("role"), msg.get("content")))

        if not normalized_messages:
            self.send_error_response(400, "No valid messages provided")
            return

        messages = normalized_messages

        last_msg = messages[-1]
        current_prompt = last_msg.get("content", "")

        # Compute hash of history (excluding last message) to check for a continued conversation.
        # Every dict here comes from _normalize_message, so key order is fixed and json.dumps
        # does not need sort_keys; the saving is small and shrinks as message content grows.
        history = messages[:-1]
        history_hash = ""
        if history:
            history_str = json.dumps(history)
            combined = f"{model}:{history_str}"
            history_hash = hashlib.sha256(combined.encode("utf-8")).hexdigest()

        conv_id = None
        if history_hash:
            with cache_lock:
                cached_id = history_to_conv_id.get(history_hash)
                if cached_id and _is_valid_conv_id(cached_id):
                    conv_id = cached_id

        current_prompt = _sanitize_prompt(current_prompt)

        # Build command to execute agentapi
        # Use '--' delimiter to prevent positional arguments/prompts from being parsed as CLI options/flags.
        if conv_id:
            logging.info(f"Continuing conversation {conv_id} using send-message...")
            cmd = ["agentapi", "send-message", "--", conv_id, current_prompt]
        else:
            logging.info("Starting new conversation...")
            if history:
                context_str = "Context of previous conversation:\n"
                for msg in history:
                    role = msg.get("role", "user").capitalize()
                    content = _sanitize_prompt(msg.get("content", ""))
                    context_str += f"{role}: {content}\n"
                context_str += "\nNow respond to the following prompt:\n"
                initial_prompt = context_str + current_prompt
            else:
                initial_prompt = current_prompt

            cmd = ["agentapi", "new-conversation", f"--model={model}", "--", _sanitize_prompt(initial_prompt)]

        # SECURITY: Log command identifiers without leaking full prompt or argument payloads to logs (.jules/sentinel.md)
        logging.info(f"Running command: {cmd[0]} {cmd[1]}")
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, check=False, shell=False)
            stdout = res.stdout
            stderr = res.stderr
            returncode = res.returncode
        except Exception as e:
            logging.error(f"Failed to execute agentapi: {str(e)}")
            self.send_error_response(500, f"Failed to execute agentapi command: {str(e)}")
            return

        logging.info(f"agentapi exit code: {returncode}")
        logging.info(f"agentapi stdout: {stdout}")
        if stderr:
            logging.warning(f"agentapi stderr: {stderr}")

        # Parse output
        parsed_conv_id, parsed_content = self.parse_agentapi_output(stdout)
        if parsed_conv_id and not _is_valid_conv_id(parsed_conv_id):
            logging.warning("Parsed conversation ID %r from agentapi output is invalid.", parsed_conv_id)
            parsed_conv_id = None

        if not parsed_content:
            try:
                data = json.loads(stdout)
                error_detail = data.get("error", "Unknown error")
            except Exception:
                error_detail = stderr or stdout or "Unknown error"
            self.send_error_response(500, f"agentapi error: {error_detail}")
            return

        # If we got a conversation ID, update the cache for the next turn
        if parsed_conv_id:
            new_history = messages + [_normalize_message("assistant", parsed_content)]
            new_history_str = json.dumps(new_history)
            new_combined = f"{model}:{new_history_str}"
            new_hash = hashlib.sha256(new_combined.encode("utf-8")).hexdigest()
            with cache_lock:
                history_to_conv_id[new_hash] = parsed_conv_id
                logging.info(f"Cached history hash {new_hash} to conversation {parsed_conv_id}")

        # Format OpenAI response
        response_id = f"chatcmpl-{parsed_conv_id}" if parsed_conv_id else f"chatcmpl-{uuid.uuid4()}"
        
        if is_chat:
            completion_response = {
                "id": response_id,
                "object": "chat.completion",
                "created": int(time.time()),
                "model": model,
                "choices": [
                    {
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": parsed_content
                        },
                        "finish_reason": "stop"
                    }
                ],
                "usage": {
                    "prompt_tokens": len(current_prompt.split()),
                    "completion_tokens": len(parsed_content.split()),
                    "total_tokens": len(current_prompt.split()) + len(parsed_content.split())
                }
            }
        else:
            completion_response = {
                "id": response_id,
                "object": "text_completion",
                "created": int(time.time()),
                "model": model,
                "choices": [
                    {
                        "text": parsed_content,
                        "index": 0,
                        "logprobs": None,
                        "finish_reason": "stop"
                    }
                ],
                "usage": {
                    "prompt_tokens": len(current_prompt.split()),
                    "completion_tokens": len(parsed_content.split()),
                    "total_tokens": len(current_prompt.split()) + len(parsed_content.split())
                }
            }

        self.send_json(200, completion_response)

    def parse_agentapi_output(self, stdout_str):
        stdout_str = stdout_str.strip()
        # Find JSON object boundaries in case of stray stdout lines
        start_idx = stdout_str.find('{')
        end_idx = stdout_str.rfind('}')
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            json_candidate = stdout_str[start_idx:end_idx+1]
            try:
                data = json.loads(json_candidate)
                err = data.get("error", "")
                if err:
                    logging.error(f"agentapi returned error: {err}")
                resp = data.get("response")
                if not resp:
                    resp = data
                if isinstance(resp, dict):
                    content = resp.get("content") or resp.get("text") or resp.get("output") or resp.get("message") or ""
                    conv_id = resp.get("conversation_id") or resp.get("conversationId") or resp.get("id") or ""
                    return conv_id, content
                elif isinstance(resp, str):
                    return None, resp
            except Exception as e:
                logging.warning(f"Failed to parse substring JSON: {e}")

        # Fallback to whole stdout string if JSON parsing failed
        return None, stdout_str

def run(port=18081, host=None):
    # SECURITY: loopback-only. This bridge is unauthenticated, so binding
    # 0.0.0.0 or any non-loopback address would expose remote prompt execution
    # into `agentapi`.
    if host is None:
        host = os.environ.get("BRIDGE_HOST", DEFAULT_HOST)
    if not _is_loopback(host):
        logging.warning(
            "Non-loopback host %r requested, but bridge is unauthenticated. "
            "Enforcing loopback (%s).",
            host,
            DEFAULT_HOST,
        )
        host = DEFAULT_HOST
    server_address = (host, port)
    httpd = http.server.ThreadingHTTPServer(server_address, OpenAIBridgeHandler)
    logging.info(f"Starting OpenAI Bridge server on {host}:{port}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logging.info("KeyboardInterrupt received.")
    logging.info("Stopping OpenAI Bridge server...")
    httpd.server_close()

if __name__ == "__main__":
    port_str = os.environ.get("PORT", "18081")
    try:
        port = int(port_str)
    except ValueError:
        port = 18081
    run(port=port)
