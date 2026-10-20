#!/usr/bin/env python3
"""Re-apply the local pi-subagents patches after an upgrade. Idempotent.

Usage: python3 apply.py [--check]
"""
import sys, shutil
from pathlib import Path

PKG = Path.home()/".config/pi/agent/npm/node_modules/pi-subagents"
if not PKG.exists():
    sys.exit(f"pi-subagents not found at {PKG}")

# (file, marker that means "already patched", old, new)
PATCHES = []

PATCHES.append((
    "src/runs/shared/subagent-control.js",
    "[local patch 2026-10-20] Absence of an activity timestamp",
    """export function deriveActivityState(input) {
    if (!input.config.enabled || input.currentTool || (input.turnCount ?? 0) === 0)
        return undefined;
    const now = input.now ?? Date.now();
    const lastActivity = input.lastActivityAt ?? input.startedAt;
    const ageMs = Math.max(0, now - lastActivity);""",
    """export function deriveActivityState(input) {
    if (!input.config.enabled || input.currentTool || (input.turnCount ?? 0) === 0)
        return undefined;
    // [local patch 2026-10-20] Absence of an activity timestamp is not evidence of idleness.
    // Falling back to startedAt made every workflow child look idle 60s after launch, because
    // workflow children never populate step.lastActivityAt and never emit output-<n>.log.
    if (input.lastActivityAt === undefined)
        return undefined;
    const now = input.now ?? Date.now();
    const lastActivity = input.lastActivityAt;
    const ageMs = Math.max(0, now - lastActivity);""",
))

OLD2 = """    const stepOutputActivityAt = (index) => {
        const step = statusPayload.steps[index];
        let lastActivityAt = step?.lastActivityAt ?? step?.startedAt ?? overallStartTime;
        lastActivityAt = Math.max(lastActivityAt, externalActivityEvidence.get(index)?.lastStreamActivityAt ?? 0);
        const outputPath = path.join(asyncDir, `output-${index}.log`);
        try {
            lastActivityAt = Math.max(lastActivityAt, fs.statSync(outputPath).mtimeMs);
        }
        catch (error) {
            if (error.code !== "ENOENT") {
                console.error(`Failed to inspect async output file '${outputPath}':`, error);
            }
        }
        return lastActivityAt;
    };"""

NEW2 = """    const stepOutputActivityAt = (index) => {
        // [local patch 2026-10-20] Workflow children never write output-<n>.log (0 of 47
        // workflow run dirs had one, vs 324 of 324 single-agent runs) and never populate
        // step.lastActivityAt, so the only signal was startedAt. status.json *is* rewritten on
        // every turn/tool transition, so its mtime is a real activity heartbeat.
        const step = statusPayload.steps[index];
        let lastActivityAt = step?.lastActivityAt ?? step?.startedAt ?? overallStartTime;
        lastActivityAt = Math.max(lastActivityAt, externalActivityEvidence.get(index)?.lastStreamActivityAt ?? 0);
        const outputPath = path.join(asyncDir, `output-${index}.log`);
        try {
            lastActivityAt = Math.max(lastActivityAt, fs.statSync(outputPath).mtimeMs);
        }
        catch (error) {
            if (error.code !== "ENOENT") {
                console.error(`Failed to inspect async output file '${outputPath}':`, error);
            }
            else if (!missingOutputLogReported.has(outputPath)) {
                missingOutputLogReported.add(outputPath);
                console.error(`No async output file '${outputPath}'; using status heartbeat for activity.`);
            }
        }
        try {
            lastActivityAt = Math.max(lastActivityAt, fs.statSync(path.join(asyncDir, "status.json")).mtimeMs);
        }
        catch (error) {
            if (error.code !== "ENOENT")
                console.error("Failed to inspect status.json for activity:", error);
        }
        return lastActivityAt;
    };
    const missingOutputLogReported = new Set();"""

PATCHES.append(("src/runs/background/subagent-runner.js",
                "[local patch 2026-10-20] Workflow children never write", OLD2, NEW2))

check = "--check" in sys.argv
applied = already = failed = 0
for rel, marker, old, new in PATCHES:
    f = PKG/rel
    if not f.exists():
        print(f"  MISSING {rel}"); failed += 1; continue
    t = f.read_text()
    if marker in t:
        print(f"  already patched: {rel}"); already += 1; continue
    if old not in t:
        print(f"  ANCHOR MISSING in {rel} - upstream changed; re-derive the patch"); failed += 1; continue
    if check:
        print(f"  would patch: {rel}"); continue
    shutil.copy2(f, str(f) + ".prepatch")
    f.write_text(t.replace(old, new, 1))
    print(f"  patched: {rel}"); applied += 1

print(f"\n  applied={applied} already={already} failed={failed}")
if applied and not check:
    print("  verify: node --check each patched file")
sys.exit(1 if failed else 0)
