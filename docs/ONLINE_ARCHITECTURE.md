# Online and social features (Phase 6 plan, not implemented)

Nothing in the offline game talks to a network. This is the plan we will review before Phase 6 starts.

## Non-negotiables

- **Server-authoritative.** The server rolls dice, validates moves, applies captures and snake bites, and decides results. Clients send intents (`roll`, `move pawn N`) and play back server events. The client never decides a winner.
- **No real-money betting or gambling.** No paid currency that can be won or lost.
- **No secrets in the client or the repository.** API keys and service credentials live on the server or in CI secrets.

## Agreed requirements (owner decisions, 2026-11-26)

### Login

| Method | Decision | Notes |
| --- | --- | --- |
| Guest | Yes (exists offline) | Play instantly; can later be linked to Google or Facebook without losing progress. |
| Google / Google Play Games | Yes | Free. Play Games also offers friends (with consent), achievements and leaderboards. |
| Facebook | Yes | Free. Needs Meta app review for the `user_friends` permission. |
| Phone number (SMS / WhatsApp) | Not for now | Per-message cost. Can be added later. |
| TikTok | Not for now | Needs TikTok app approval and custom server code. |
| Apple | Only if an iPhone version is released | Apple requires it when other social logins are offered on iOS. |

One account can have several linked logins.

### Friends

- Facebook friends who **also play** the game (the only list Facebook allows) are added as in-game friends automatically.
- Google Play Games friends can be added the same way when the player consents.
- Manual friend requests by player ID/room code remain available.

### Pause

- **Offline:** the game can be paused (current behaviour).
- **Online:** the game never pauses. The menu opens over a running match (sound, chat, leave). A turn timer runs on the server; after a missed turn or a disconnect, the server waits a short grace period, then plays an automatic move or skips the turn. A reconnecting player rejoins the same match.

### Match history

- The server stores every online match per user: date, mode, players, finishing places, captures.
- History is shown from the user's account on any device and cannot be edited by the client.

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
