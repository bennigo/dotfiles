"""Mocked Sway IPC tests: no windows or physical displays are modified."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

SOURCE = Path(__file__).resolve().parents[1] / "sway/.config/sway/scripts/display-toggle.py"
SPEC = importlib.util.spec_from_file_location("display_toggle", SOURCE)
assert SPEC is not None and SPEC.loader is not None
display = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(display)


class DisplayTests(unittest.TestCase):
    def setUp(self):
        self.outputs = [
            {"name": "eDP-1", "active": True},
            {"name": "HDMI-A-1", "active": True},
        ]
        self.mirror = {"id": 90, "pid": 123, "app_id": display.APP_ID, "name": display.TITLE}

    def test_detect_outputs_without_hardcoding_external_connector(self):
        self.outputs[1]["name"] = "DP-3"
        self.assertEqual(display.select_outputs(self.outputs), ("eDP-1", "DP-3"))

    def test_inactive_and_missing_external_rejected(self):
        self.outputs[1]["active"] = False
        with self.assertRaisesRegex(RuntimeError, "Enginn"):
            display.select_outputs(self.outputs)

    def test_missing_laptop_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "fartölvuskjár"):
            display.select_outputs(self.outputs[1:])

    def test_multiple_external_requires_explicit_selection(self):
        self.outputs.append({"name": "DP-2", "active": True})
        with self.assertRaisesRegex(RuntimeError, "--output"):
            display.select_outputs(self.outputs)
        self.assertEqual(display.select_outputs(self.outputs, "DP-2"), ("eDP-1", "DP-2"))

    def test_invalid_explicit_target_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "ekki virkur"):
            display.select_outputs(self.outputs, "eDP-1")

    def test_only_owned_mirror_matches_including_floating_nodes(self):
        other = dict(self.mirror, id=91, name="Other mirror")
        tree = {"nodes": [other], "floating_nodes": [self.mirror]}
        self.assertEqual(display.mirrors(tree), [self.mirror])

    def test_output_name_cannot_inject_sway_commands(self):
        for name in ('DP-1"; exit', "DP-1\nexit", "DP-1, disable"):
            with self.assertRaises(ValueError):
                display.quote(name)

    @patch.object(display.subprocess, "run")
    def test_ipc_checks_command_errors_and_malformed_json(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, '[{"success":false,"error":"bad command"}]')
        with self.assertRaisesRegex(RuntimeError, "bad command"):
            display.ipc("command", "test")
        run.return_value = subprocess.CompletedProcess([], 0, "not JSON")
        with self.assertRaisesRegex(RuntimeError, "Ógilt svar"):
            display.ipc("get_tree")

    @patch.object(display, "notify")
    @patch.object(display, "ipc")
    def test_toggle_off_closes_only_mirror_even_after_unplug(self, ipc, notify):
        ipc.return_value = {"nodes": [self.mirror]}
        display.toggle("toggle", None, Path("/unused"))
        self.assertEqual([call.args for call in ipc.call_args_list], [
            ("get_tree",), ("command", "[con_id=90] kill"),
        ])

    @patch.object(display, "notify")
    @patch.object(display, "ipc")
    def test_explicit_modes_are_idempotent(self, ipc, notify):
        ipc.return_value = {"nodes": [self.mirror]}
        display.toggle("mirror", None, Path("/unused"))
        self.assertEqual(ipc.call_count, 1)
        ipc.reset_mock()
        ipc.return_value = {}
        display.toggle("extend", None, Path("/unused"))
        self.assertEqual(ipc.call_count, 1)

    @patch.object(display, "notify")
    @patch.object(display.shutil, "which", return_value="/usr/bin/wl-mirror")
    @patch.object(display.subprocess, "Popen")
    @patch.object(display, "ipc")
    def test_start_preserves_existing_windows_modes_and_keyboard_focus(self, ipc, popen, which, notify):
        original = {"id": 40, "app_id": "terminal", "focused": True}
        ipc.side_effect = [
            {"nodes": [original]}, self.outputs,
            [{"focused": True, "output": "eDP-1"}],
            {"floating_nodes": [self.mirror]}, [], [],
        ]
        process = Mock(pid=123)
        process.poll.return_value = None
        popen.return_value = process
        with tempfile.TemporaryDirectory() as directory:
            display.toggle("toggle", None, Path(directory))
        commands = [call.args[1] for call in ipc.call_args_list if call.args[0] == "command"]
        self.assertEqual(commands, [
            '[con_id=90] floating enable, move container to output "HDMI-A-1", fullscreen enable',
            '[con_id=40] focus',
        ])
        self.assertIn("screencopy-shm", popen.call_args.args[0])
        self.assertIn("fit", popen.call_args.args[0])
        self.assertEqual(popen.call_args.args[0][-1], "eDP-1")
        process.terminate.assert_not_called()

    @patch.object(display, "notify")
    @patch.object(display.shutil, "which", return_value=None)
    @patch.object(display, "ipc")
    def test_missing_dependency_fails_before_creating_window(self, ipc, which, notify):
        ipc.side_effect = [{}, self.outputs]
        with self.assertRaisesRegex(RuntimeError, "wl-mirror vantar"):
            display.toggle("toggle", None, Path("/unused"))

    @patch.object(display, "notify")
    @patch.object(display.shutil, "which", return_value="/usr/bin/wl-mirror")
    @patch.object(display.subprocess, "Popen")
    @patch.object(display, "ipc")
    def test_ipc_failure_terminates_only_new_child(self, ipc, popen, which, notify):
        ipc.side_effect = [{}, self.outputs, [], RuntimeError("disconnected")]
        process = Mock(pid=123)
        process.poll.return_value = None
        popen.return_value = process
        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(RuntimeError, "disconnected"):
            display.toggle("toggle", None, Path(directory))
        process.terminate.assert_called_once()
        process.wait.assert_called_once()


if __name__ == "__main__":
    unittest.main()
