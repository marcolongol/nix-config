---
name: interview-me
description: Interview the user to turn a vague request into a clear brief (job, why, rules, definition of done)
disable-model-invocation: true
---

The user has a task but not a clear prompt for it. Interview them until you can
write a brief they agree with. Starting idea, possibly empty: $ARGUMENTS

## Interview
- Before asking, read what you can find yourself (repo, files, git log, memory), so
  you only ask what the user alone can answer.
- Use `AskUserQuestion`, 1–3 questions per round, each with concrete options built
  from what you found. Build each round on the previous answers.
- Cover, in this order:
  1. **Job**: what to build or change, and where.
  2. **Why**: the goal behind it; this decides trade-offs.
  3. **Rules**: constraints, conventions, what must not change, what is out of scope.
  4. **Done**: how to verify it worked (tests, build, observable behavior).
- Stop asking as soon as every section is clear. Don't ask what has a sensible
  default; note the default in the brief instead.

## Brief
Show the brief in this shape:

```
Job:   ...
Why:   ...
Rules: ...
Done:  ...
Defaults assumed: ...
```

Ask whether it's right; revise until the user confirms.

## Then
Ask with `AskUserQuestion`: start the task now, or output the brief as a
ready-to-paste prompt. Do what they pick.
