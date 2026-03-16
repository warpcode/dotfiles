---
rule: field
name: status
for: task
type: select
values: [backlog, in-progress, blocked, in-review, done]
default: backlog
---