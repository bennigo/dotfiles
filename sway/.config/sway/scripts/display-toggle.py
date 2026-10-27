#!/usr/bin/env python3
"""Toggle a fullscreen laptop mirror without moving existing windows or outputs."""

import argparse
import contextlib
import fcntl
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

APP_ID = "at.yrlf.wl_mirror"
TITLE = "Sway laptop mirror"


def ipc(kind, command=None):
    args = ["swaymsg", "-r", "-t", kind]
    if command is not None:
        args.append(command)
    result = subprocess.run(args, check=True, capture_output=True, text=True, timeout=5)
    try:
        reply = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("Ógilt svar frá Sway.") from error
    if kind == "command":
        for item in reply:
            if not item.get("success"):
                raise RuntimeError(item.get("error", "Sway command failed"))
    return reply


def walk(node):
    yield node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        yield from walk(child)


def mirrors(tree):
    return [node for node in walk(tree)
            if node.get("app_id") == APP_ID and node.get("name") == TITLE]


def select_outputs(outputs, target=None):
    active = [output for output in outputs if output.get("active")]
    panels = [output for output in active
              if output["name"].startswith(("eDP-", "LVDS-", "DSI-"))]
    if len(panels) != 1:
        raise RuntimeError("Einn virkur fartölvuskjár þarf að vera tengdur.")
    source = panels[0]["name"]
    external = [output["name"] for output in active if output["name"] != source]
    if target:
        if target not in external:
            raise RuntimeError(f"Ytri skjárinn {target} er ekki virkur.")
        return source, target
    if not external:
        raise RuntimeError("Enginn virkur ytri skjár tengdur.")
    if len(external) > 1:
        raise RuntimeError("Fleiri en einn ytri skjár: notaðu --output SKJÁNAFN.")
    return source, external[0]


def quote(value):
    # Output names normally cannot contain these, but never interpolate IPC syntax.
    if any(char in value for char in '\n\r\x00;,[\\"'):
        raise ValueError("Ógilt skjánafn.")
    return f'"{value}"'


def notify(message, error=False):
    print(message, file=sys.stderr if error else sys.stdout)
    if shutil.which("notify-send"):
        with contextlib.suppress(OSError, subprocess.TimeoutExpired):
            subprocess.run(["notify-send", "-a", "Skjáhamur", "-t", "3500",
                            "-u", "critical" if error else "normal",
                            "Skjáhamur", message], timeout=3, check=False)


def toggle(mode, target, runtime):
    tree = ipc("get_tree")
    existing = mirrors(tree)
    if existing:
        if mode == "mirror":
            return
        for node in existing:
            ipc("command", f'[con_id={int(node["id"])}] kill')
        notify("Sjálfstætt vinnusvæði á ytri skjá.")
        return
    if mode == "extend":
        notify("Sjálfstætt vinnusvæði er þegar virkt.")
        return

    source, destination = select_outputs(ipc("get_outputs"), target)
    source_q, destination_q = quote(source), quote(destination)
    if not shutil.which("wl-mirror"):
        raise RuntimeError("wl-mirror vantar: sudo apt install wl-mirror")

    focused = next((node["id"] for node in walk(tree)
                    if node.get("focused") and node.get("app_id")), None)
    focused_workspace = next((ws for ws in ipc("get_workspaces") if ws.get("focused")), {})
    # SHM avoids cross-GPU DMA-BUF import failures on Intel/NVIDIA laptops.
    # Fit preserves the entire 16:10 panel on e.g. a 16:9 projector.
    with (runtime / "display-mirror.log").open("w") as log:
        process = subprocess.Popen(
            ["wl-mirror", "--title", TITLE, "--backend", "screencopy-shm",
             "--scaling", "fit", "--fullscreen-output", destination, source],
            stdin=subprocess.DEVNULL, stdout=log, stderr=log,
            start_new_session=True, close_fds=True,
        )
    try:
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(f"Speglun ræstist ekki. Sjá {runtime / 'display-mirror.log'}")
            node = next((node for node in mirrors(ipc("get_tree"))
                         if node.get("pid") == process.pid), None)
            if node:
                ipc("command", f'[con_id={int(node["id"])}] floating enable, '
                    f'move container to output {destination_q}, fullscreen enable')
                # Keep keyboard control on the laptop, not on the fullscreen mirror.
                if focused is not None and focused_workspace.get("output") == source:
                    ipc("command", f"[con_id={int(focused)}] focus")
                else:
                    ipc("command", f"focus output {source_q}")
                notify("Speglun virk — F7 skiptir aftur í sjálfstætt vinnusvæði.")
                return
            time.sleep(0.05)
        raise RuntimeError("Speglun svaraði ekki innan 8 sekúndna.")
    except Exception:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", nargs="?", choices=("toggle", "mirror", "extend"), default="toggle")
    parser.add_argument("--output", help="Target output when several external displays are connected")
    args = parser.parse_args(argv)
    try:
        if not os.environ.get("SWAYSOCK"):
            raise RuntimeError("Keyra þarf þetta innan Sway.")
        runtime = Path(os.environ["XDG_RUNTIME_DIR"])
        os.umask(0o077)
        with (runtime / "display-mirror.lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return 0  # Ignore repeated presses while a transition is in progress.
            toggle(args.mode, args.output, runtime)
        return 0
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        notify(str(error), error=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
