---
description: Deep implementation workflow — thorough scouting, architecture, planning, audit, and implementation. For complex changes.
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "deep-scout" agent to thoroughly analyze the codebase around: {{focus}}
2. Then, use the "architect" agent to design the solution approach using the context from the previous step (use {previous} placeholder)
3. Then, use the "planner" agent to create a detailed implementation plan from the architecture (use {previous} placeholder)
4. Then, use the "worker" agent to implement the plan (use {previous} placeholder)
5. Finally, use the "auditor" agent to security-review the implementation (use {previous} placeholder)

Execute this as a chain, passing output between steps via {previous}. This is the heavyweight path — for complex, security-sensitive, or architecturally significant changes.
