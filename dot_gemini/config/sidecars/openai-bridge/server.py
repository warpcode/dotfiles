import http.server
import json
import subprocess
import os
import hashlib
import threading
import uuid
import time
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Thread-safe in-memory cache mapping history hashes to conversation IDs
cache_lock = threading.Lock()
history_to_conv_id = {}

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

    def handle_completions(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self.send_error_response(400, "Empty request body")
            return

        body = self.rfile.read(content_length)
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
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self.send_error_response(400, "Empty request body")
            return

        body = self.rfile.read(content_length)
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
        allowed_models = ["flash_lite", "flash", "pro"]
        if model not in allowed_models:
            logging.warning(f"Requested model '{model}' not recognized. Falling back to 'flash_lite'.")
            model = "flash_lite"

        if not messages:
            self.send_error_response(400, "No messages provided")
            return

        last_msg = messages[-1]
        current_prompt = last_msg.get("content", "")

        # Compute hash of history (excluding last message) to check for a continued conversation
        history = messages[:-1]
        history_hash = ""
        if history:
            history_str = json.dumps(history, sort_keys=True)
            combined = f"{model}:{history_str}"
            history_hash = hashlib.sha256(combined.encode("utf-8")).hexdigest()

        conv_id = None
        if history_hash:
            with cache_lock:
                conv_id = history_to_conv_id.get(history_hash)

        # Build command to execute agentapi
        if conv_id:
            logging.info(f"Continuing conversation {conv_id} using send-message...")
            cmd = ["agentapi", "send-message", conv_id, current_prompt]
        else:
            logging.info("Starting new conversation...")
            if history:
                context_str = "Context of previous conversation:\n"
                for msg in history:
                    role = msg.get("role", "user").capitalize()
                    content = msg.get("content", "")
                    context_str += f"{role}: {content}\n"
                context_str += "\nNow respond to the following prompt:\n"
                initial_prompt = context_str + current_prompt
            else:
                initial_prompt = current_prompt

            cmd = ["agentapi", "new-conversation", f"--model={model}", initial_prompt]

        logging.info(f"Running command: {' '.join(cmd)}")
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, check=False)
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
            new_history = messages + [{"role": "assistant", "content": parsed_content}]
            new_history_str = json.dumps(new_history, sort_keys=True)
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

def run(port=18081):
    server_address = ("", port)
    httpd = http.server.HTTPServer(server_address, OpenAIBridgeHandler)
    logging.info(f"Starting OpenAI Bridge server on port {port}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logging.info("KeyboardInterrupt received.")
    logging.info("Stopping OpenAI Bridge server...")
    httpd.server_close()

if __name__ == "__main__":
    # Dump environment variables for inspection/debugging
    logging.info("Dump of Environment Variables:")
    for k, v in sorted(os.environ.items()):
        if "TOKEN" in k or "KEY" in k or "SECRET" in k or "PASSWORD" in k:
            logging.info(f"  {k}=********")
        else:
            logging.info(f"  {k}={v}")

    port_str = os.environ.get("PORT", "18081")
    try:
        port = int(port_str)
    except ValueError:
        port = 18081
    run(port=port)
