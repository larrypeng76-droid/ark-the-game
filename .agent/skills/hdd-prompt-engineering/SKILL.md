---
name: hdd-prompt-engineering
description: HDD protocol for prompt engineering and AI-facing documentation. Use for planning/spec/review/explanation prompts to maximize Chinese information density with English concept anchors, improve machine readability, and reduce token cost.
---

# HDD Prompt Engineering
> TYPE: STANDARD / WRITING-PROTOCOL
> STATUS: ACTIVE

## 1. AXIOM
- Goal function: `InfoDensity ↑`, `Ambiguity ↓`, `TokenCost ↓`.
- Expression mode: `CN logic` + `EN anchors` (terms, APIs, phases, constraints).
- Chinese high-density expression is required by default (`MUST`), English is anchor layer (`SHOULD`) not prose layer.
- Prefer structure over prose: `rules/tables/algo/decision` > paragraphs.

## 2. OUTPUT SHAPE (default)
1. `AXIOM`: 1-3 non-negotiable truths.
2. `CONSTRAINTS`: hard boundaries (`must/forbid/only`).
3. `ALGO`: numbered execution flow (`Input -> Process -> Output`).
4. `CHECK/GATE`: verification steps and pass criteria.
5. `DELIVERABLE`: exact output form (files/lines/sections).

## 3. LANGUAGE POLICY
- Chinese is the primary carrier for logic compression (`MUST`).
- English is only for concept anchors and stable identifiers (`SHOULD`), not full-sentence narration.
- Use fixed anchors for recurring concepts (e.g. `Boundary`, `Dependency`, `Gate`, `Fail-safe`, `Regression`).
- No decorative wording, no motivational prose, no background padding.
- Mixed-language line pattern (default): `中文结论: EN_Anchor / EN_Term`.

## 4. TOKEN ECONOMY RULES
- One bullet = one new fact.
- Remove synonym duplicates and explanatory restatement.
- Prefer symbolic patterns: `A -> B`, `IF X THEN Y`, `X => Y`.
- Prefer Chinese shorthand for logic; avoid bilingual duplication of the same sentence.
- Keep examples minimal and only when disambiguation is required.

## 4.1 MIXED-LANGUAGE MINIMAL FORM
- Use this compact form by default:
  - `结论(中文): Anchor(EN)`
  - `约束(中文): MUST/FORBID(EN)`
  - `流程(中文): Input->Process->Output(EN)`
- Forbidden pattern: full Chinese paragraph + full English paragraph conveying identical meaning.

## 5. PROMPT TEMPLATE
```md
# [TASK] (HDD)
> GOAL: [one-line objective]

## AXIOM
- [...]

## CONSTRAINTS
- MUST: [...]
- FORBID: [...]

## ALGO
1. [Input] -> [Process] -> [Output]
2. IF [Condition] THEN [Action]

## GATE
- [check-1]
- [check-2]

## DELIVERABLE
- [exact output format]
```

## 6. REVIEW MODE
- Findings first, severity ordered.
- Every finding includes precise path + line.
- Summary is secondary; no-finding case must be explicit.

## 7. FAILURE HANDLING
- If conflict exists: prioritize system/developer/user instruction order.
- If requirement is unclear: state assumption in one line, continue execution.
