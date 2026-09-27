import unittest

import importlib.util

# Load the wrapper since it has hyphens and doesn't end in .py... wait, it DOES end in .py
# but has hyphens in the filename `executable_ai-guard-wrapper.py`.


spec = importlib.util.spec_from_file_location("ai_guard_wrapper", "dot_gemini/config/executable_ai-guard-wrapper.py")
ai_guard_wrapper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ai_guard_wrapper)


class TestAiGuardWrapperHelper(unittest.TestCase):
    def test_extract_command_first_hit(self):
        mapping = {"CommandLine": "  echo first  ", "cmd": "ignore"}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo first")

    def test_extract_command_fallthrough_key(self):
        mapping = {"ignore": "this", "cmd": " echo fallback "}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo fallback")

    def test_extract_command_skips_non_string(self):
        # Even if CommandLine is present, if it's not a string, it should fall through to cmd
        mapping = {"CommandLine": {"complex": "object"}, "cmd": " echo real "}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo real")

    def test_extract_command_empty_string_triggers_payload_fallthrough(self):
        # We test the logic in main by calling extract_command.
        # If tool_args has an empty string command, extract_command returns an empty string.
        # This tests that the function behaves correctly for empty string,
        # the fallthrough to payload is tested separately or implicit from main's `if not cmd` logic.
        tool_args = {"CommandLine": "   "}
        cmd = ai_guard_wrapper.extract_command(tool_args)
        self.assertEqual(cmd, "")

        # Test the exact `not cmd` logic as in main
        payload = {"cmd": " payload_cmd "}
        if not cmd and isinstance(payload, dict):
            cmd = ai_guard_wrapper.extract_command(payload)

        self.assertEqual(cmd, "payload_cmd")

    def test_extract_command_multi_quote_strip(self):
        # CRITICAL BEHAVIOR: strips all leading and trailing quote characters
        # "\"quoted\"" -> "quoted"
        mapping = {"CommandLine": "'\"\"echo multi\"'\""}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo multi")

if __name__ == "__main__":
    unittest.main()
