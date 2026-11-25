class_name OnlineService
extends RefCounted
## Boundary for future online play (Phase 6). Nothing here talks to a network.
##
## Design rule for Phase 6: online matches are server-authoritative. The server
## rolls the dice, validates every move, applies captures and decides the winner.
## The client only sends intents ("roll", "move pawn 2") and plays back results.
## See docs/ONLINE_ARCHITECTURE.md.


## Online features are not available in the offline version.
static func is_available() -> bool:
	return false
