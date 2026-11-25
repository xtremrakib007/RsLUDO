# Online and social features (Phase 6 plan, not implemented)

Nothing in the offline game talks to a network. This is the plan we will review before Phase 6 starts.

## Non-negotiables

- **Server-authoritative.** The server rolls dice, validates moves, applies captures and snake bites, and decides results. Clients send intents (`roll`, `move pawn N`) and play back server events. The client never decides a winner.
- **No real-money betting or gambling.** No paid currency that can be won or lost.
- **No secrets in the client or the repository.** API keys and service credentials live on the server or in CI secrets.

## Why the offline code is ready for this

- `LudoRulesConfig.to_dict()/from_dict()` lets the server send the agreed rules.
- `LudoPlayer.ControlType.REMOTE` marks players whose moves come from the server.
- The Phase 2 engine will be pure functions over plain `MatchState` data producing events, so the same rules can run server-side and the client can replay events.

## Candidate low-cost stack (to decide in Phase 6)

| Need | Free/open-source options |
| --- | --- |
| Match server | Nakama (open source, self-hosted) with authoritative match handlers, or a headless Godot server |
| Accounts, friends, chat, leaderboards | Nakama built-ins |
| Voice (optional) | WebRTC (Godot has WebRTC support); a TURN server such as coturn |
| Hosting | One small VPS to start |

## Feature list

Online 2/4-player games, quick match, private rooms with codes, friends and invites, profiles and avatars, text chat, optional voice with mute, reconnection, match history, achievements and leaderboards, reporting and blocking, moderation and privacy controls.
