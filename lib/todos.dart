// =====================================================
// 🛑 P0 — CRITICAL FIXES
// =====================================================

//// (P0): Email app not opening
//// (P0): problems with replying with Voice messages again
//// (P0): Navigation janky 
//// (P0): Chat search not cleared upon popping screen
//// (P0): Init message errors
//// (P0): First message does not change isSender state (must rebind Isar instance properly).
//TODO (P0): Reply Anchor does not respect system UI
//TODO (P0): Videos to be added
//TODO (P0): Fonts not being updated
//TODO (P0): Chat deletes must be undoable
//TODO (P0): Chat tiles must be pinnable
//TODO (P0): Notifier needs robustness and double-checks for Isar links, async races, and null states.
//TODO (P0): Fix state desynchronization issues (allMessages vs state.messages).
//TODO (P0): Full-sized images being shown as thumbnails — fix aspect ratio or cached preview source.

// =====================================================
// ⚠️ P1 — HIGH PRIORITY
// =====================================================

//// (P1): Filter homescreen chats
//// (P1): Loading indicator for homescreen chatlist
//// (P1): Convert ReplyAnchor to Overlay to fix animation issues
//// (P1): Crop rotation is
//TODO (P1): Revamp overall MessageBar structure for unified text/media/reply handling.
//TODO (P1): Ensure consistent state updates after forwarding, replying, or deleting messages.
//TODO (P1): Fix transaction boundary issues when saving linked media or replies.
//TODO (P1): Everything rebuilds when long-press is called — optimize rebuild granularity.
//TODO (P1): Clear Chat does not delete all messages properly (linked cleanup issue).
//TODO (P1): Audio/Documents being replied to cause errors (replyWrapper or media link issue).
//TODO (P1): Prevent duplicate media deletion — detect shared paths before delete.
//TODO (P1): Hero Overlay needs implementation in ChatDetailScreen (for smooth media transitions).
//TODO (P1): Non-image media (audio/docs/videos) need proper formatting in ChatDetailScreen.
//TODO (P1): Audio players need to be robusted (seek, pause/resume, error states).
//TODO (P1): Search does not show new messages — rebind live updates after send.
//TODO (P1): Search needs to be handled inside Forward screen (to find target chats).
//TODO (P1): Square images not being displayed properly (use BoxFit.cover + container ratio).

// =====================================================
// ⚙️ P2 — MEDIUM PRIORITY
// =====================================================

//TODO (P2): Add safe fallbacks for missing or corrupted media (placeholder logic).
//TODO (P2): Handle message updates atomically to prevent partial saves under race conditions.
//TODO (P2): Camera needs robustness (permission, error handling, cancel flow).
//TODO (P2): GIF / Pasting needs robustness (gracefully reject bad or large inputs).
//TODO (P2): Reply wrapper needs to handle all media types (audio, document, video, etc.).
//TODO (P2): Improve Forward flow (multi-select chats, confirmation UI, error handling).
//TODO (P2): Add “Forwarded” label or subtle visual indicator to forwarded messages.
//TODO (P2): Add snackbar/toast confirmations for delete, copy, forward.
//TODO (P2): Improve long-press menu animation & delay timing.
//TODO (P2): Add smooth scroll-to-anchor animation for replies.

// =====================================================
// 💫 P3 — NICE TO HAVE / ENHANCEMENTS
// =====================================================

//TODO (P3): Add empty-state animations for new chats & search results.
//TODO (P3): Improve keyboard/emoji picker transition (avoid layout jumps).
//TODO (P3): Audio record UI / overlay needs implementation (waveform, cancel, timer).
//TODO (P3): Add message delivery indicators (sent/read).
//TODO (P3): Add multi-select actions (bulk forward, delete, export).
//TODO (P3): Implement Isar migration strategy for schema updates.
//TODO (P3): Add database compaction & cleanup logic.
//TODO (P3): Implement offline queue for delayed message sends.
//TODO (P3): Add logging/analytics hooks for debugging and user insights.
//TODO (P3): Add thumbnail caching & fade-in loading for large media.
