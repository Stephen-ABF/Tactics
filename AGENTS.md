# Thornwake working agreement

- Repository: Stephen-ABF/Tactics. Godot 4.7.2, standard GDScript, Compatibility renderer.
- `docs/PROJECT_STATUS.md` is the current PM scope/status and `docs/TEAM_ROLES.md` defines handoffs. User instructions take priority.
- Keep the game offline and single player. No remote analytics, SDKs or purchases without a new requirement.
- Work on a feature branch and leave reviewable changes in a draft PR. The user or designated PM decides when to merge. Do not merge to main automatically.
- Rules belong in the deterministic reducer, not the 3D animation. Keep displayed damage consistent with reducer hit records.
- Item locks must be enforced in backend operations. Save restoration must validate before replacing state and preserve the pre-import save.
- Run `python3 tools/run_checks.py --godot /path/to/Godot` before delivery. Record actual results and distinguish simulation, rendered UI checks, hardware testing and human playtesting.
- Never claim independent audit when the same agent wrote and reviewed the code. Human/device/store gates stay open until actually performed.
- The public test-signing fixture is exclusively for debug APK continuity. Never use it for release signing or replace it casually.
