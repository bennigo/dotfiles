---
description: Auto-route a task — classify and recommend the optimal agent/workflow. No implementation.
argument-hint: "<task description>"
---
Use the subagent tool with a single "router" agent:

Task: Classify this request and recommend the optimal agent(s) and workflow: {{focus}}

The router will analyze the task and output:
- Task type classification
- Complexity level
- Recommended workflow chain
- Estimated cost

Based on the router's recommendation, the user will then invoke the appropriate workflow (/implement, /quick, /implement-deep, /research, /audit, /architecture, /db-analyze).
