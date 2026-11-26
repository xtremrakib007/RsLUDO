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

## Chosen design (2026-11-26)

| Need | Choice | Cost |
| --- | --- | --- |
| Game server | **Headless Godot** running the **same rules code** as the app (`LudoRules`, `SnlEngine`), so client and server can never disagree | Free |
| Hosting | **Oracle Cloud Always Free** Ampere VM (Ubuntu), Singapore | Free |
| Secure connection | **Caddy** reverse proxy with automatic Let's Encrypt certificate on a **DuckDNS** name; clients connect with `wss://` | Free |
| Accounts | **Firebase Authentication** (anonymous guests first; Google and Facebook later), used from the app through Firebase's REST API | Free (Spark plan) |
| Profiles, friends, match history | **Firestore**, written only by the server with a service account | Free tier |
| Deploys | GitHub Actions workflow over SSH (key in GitHub secrets) | Free |

Setup steps for the owner: `ONLINE_SETUP.md`.

### How a match works

1. The app signs in (anonymous guest for now) and gets a Firebase ID token.
2. It opens `wss://<server>/play` and sends `hello {token}`. The server checks the
   token's signature against Google's public keys, its audience (project ID) and expiry.
3. `create_room {mode, players, board}` returns a 6-letter **room code**; friends send
   `join_room {code}`. `quick_match {mode, players}` puts the player in a queue.
4. When the room is full the server starts the match. **Only the server rolls the
   dice and applies moves**, using the same rule engines as offline. Clients send
   intents (`roll`, `move {pawn}`) and receive the resulting `GameEvent`s, which they
   animate exactly like offline play.
5. **No pause online.** A turn timer (about 20 s) makes an automatic move or skips;
   a disconnected player has a grace period (about 60 s) to reconnect with the
   same room and token before being replaced by automatic moves.
6. At the end the server writes the match to Firestore (`matches/{id}`) and updates
   each player's history and statistics (`users/{uid}`).

### Security rules

- Server-authoritative: the client cannot choose dice values, move out of turn or report results.
- Firestore rules deny all client access; only the server (service account) reads and writes.
- The service-account key lives only in GitHub secrets and on the server (`/etc/rs-ludo`, readable only by the service).
- Messages are size-limited and rate-limited; room codes avoid look-alike letters.

### Build order

1. Server skeleton, deploy workflow, health check.
2. Guest sign-in, Create Room / Join Room with a code, Classic Ludo online.
3. Snakes & Ladders online, reconnect, turn timer.
4. Quick Match.
5. Online profile and history; Friends (friend codes), then Google and Facebook login.

## Feature list

Online 2/4-player games, quick match, private rooms with codes, friends and invites, profiles and avatars, text chat, optional voice with mute, reconnection, match history, achievements and leaderboards, reporting and blocking, moderation and privacy controls.
