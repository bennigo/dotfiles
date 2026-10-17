"""Tests use temporary files and mocked Sway IPC; no desktop windows are changed."""

import contextlib
import importlib.machinery
import importlib.util
import io
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "local_bin/.local/bin/zathura-tabs"
LOADER = importlib.machinery.SourceFileLoader("zathura_tabs", str(SOURCE))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
assert SPEC is not None
tabs = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(tabs)


class PdfFilesTests(unittest.TestCase):
    def test_directory_is_sorted_case_insensitive_and_not_recursive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("b.PDF", "A.pdf", "notes.txt"):
                (root / name).touch()
            (root / "nested.pdf").mkdir()
            (root / "nested.pdf/hidden.pdf").touch()
            self.assertEqual(tabs.pdf_files([directory]), [root / "A.pdf", root / "b.PDF"])

    def test_explicit_paths_preserve_order_and_deduplicate(self):
        with tempfile.TemporaryDirectory() as directory:
            paths = [Path(directory) / name for name in ("quote'; semi;.pdf", "other.pdf")]
            for path in paths:
                path.touch()
            self.assertEqual(tabs.pdf_files([*map(str, paths), str(paths[0])]), paths)

    def test_empty_directory_fails(self):
        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(ValueError, "No PDFs"):
            tabs.pdf_files([directory])

    def test_non_pdf_fails(self):
        with tempfile.NamedTemporaryFile(suffix=".txt") as file, self.assertRaisesRegex(ValueError, "Not a PDF"):
            tabs.pdf_files([file.name])

    def test_missing_path_fails(self):
        with tempfile.TemporaryDirectory() as directory, self.assertRaises(FileNotFoundError):
            tabs.pdf_files([str(Path(directory) / "missing.pdf")])


class SwayTests(unittest.TestCase):
    def test_pid_lookup_includes_scratchpad_floating_nodes(self):
        tree = {"nodes": [{"floating_nodes": [{"id": 7, "pid": 123, "app_id": tabs.APP_ID}]}]}
        self.assertEqual(tabs.window_for_pid(tree, 123), 7)
        self.assertIsNone(tabs.window_for_pid(tree, 456))

    def test_pid_lookup_ignores_other_app(self):
        self.assertIsNone(tabs.window_for_pid({"id": 7, "pid": 123, "app_id": "terminal"}, 123))

    @patch.object(tabs.subprocess, "run")
    def test_failed_ipc_reply_is_not_silently_ignored(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, '[{"success":false,"error":"bad command"}]')
        with self.assertRaisesRegex(RuntimeError, "bad command"):
            tabs.sway("layout tabbed")

    @patch.object(tabs.shutil, "which", return_value="/usr/bin/tool")
    @patch.dict(tabs.os.environ, {"SWAYSOCK": "mock-sway-socket"})
    @patch.object(tabs, "open_pdf", side_effect=[101, 102])
    @patch.object(tabs, "sway")
    @patch.object(tabs, "pdf_files", return_value=[Path("a';.pdf"), Path("b.pdf")])
    def test_only_new_windows_move_to_tabbed_workspace(self, files, sway, open_pdf, which):
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(tabs.main([]), 0)
        commands = [call.args[0] for call in sway.call_args_list]
        self.assertEqual(commands, [
            'workspace "pdfs"; layout tabbed',
            '[con_id=101] move container to workspace "pdfs", floating disable',
            '[con_id=102] move container to workspace "pdfs", floating disable',
            'workspace "pdfs"; [con_id=101] focus',
        ])
        self.assertNotIn("a';.pdf", " ".join(commands))
        self.assertEqual(open_pdf.call_args_list[0].args, (Path("a';.pdf"),))

    @patch.object(tabs, "pdf_files", return_value=[Path("a.pdf")])
    @patch.object(tabs, "sway")
    def test_invalid_workspace_fails_before_ipc(self, sway, files):
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(tabs.main(["--workspace", "bad\nname"]), 1)
        sway.assert_not_called()


if __name__ == "__main__":
    unittest.main()
