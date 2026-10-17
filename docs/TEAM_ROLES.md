# Suggested AI team

One PM owns the source of truth. The minimum standing team is PM, Game Designer, Developer and independent Audit. Data Science, Market Research and UI/Art are specialist work queues; activate them when their evidence or deliverables are needed. Seven roles do not require seven continuously running sessions.

| Role | Owns | Required handoff |
| --- | --- | --- |
| PM | Approved scope, priorities, acceptance, build status, merge decision | Task ID, requirement, boundaries, acceptance gate |
| Game Designer | Rules, encounters, gear decisions, progression, difficulty intent | Implementable rules, examples, edge cases and tuning targets |
| Developer | GDScript, scenes, tools, migrations, tests and exports | Commit/PR, implemented behavior, evidence, limitations |
| Audit | Independent review of behavior, saves, destructive operations and regressions | Reproducible findings with severity and acceptance/retest result |
| Data Scientist | Local metrics, simulations, experiments and uncertainty | Reproducible methods, denominators, findings; no invented human validation |
| Market Research | Relevant public comparables, positioning and evidence | Dated primary sources; separate observation from judgment |
| UI / Graphic Designer | Touch flows, readability, art direction and asset specs | Screens/assets, dimensions, interaction states and licenses |

Flow: user → PM → relevant specialists → PM-approved implementation brief → Developer → independent Audit → PM routes findings back to the right specialist → retest → PM/user merge decision.

This update is implemented by one development partner. No separate agents or independent audit sessions have been created. The automated checks and self-review are not an independent audit. Role separation is most valuable before a public release or a substantial economy expansion; market research need not repeat for every bug fix.
