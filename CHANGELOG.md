# Changelog

## 3.8.0

### Added

- `OmniAI::Anthropic::Chat::Model::CLAUDE_OPUS_5_5` (`"claude-opus-5-5"`).

### Changed

- The generic `CLAUDE_OPUS` alias now points to `CLAUDE_OPUS_5_5` (was `CLAUDE_OPUS_5`). `DEFAULT_MODEL` is unchanged (`claude-sonnet-5`). Pin `CLAUDE_OPUS_5` to keep the previous model.

  Opus 5.5 defaults to `medium` effort (Opus 5: `high`); pass `thinking: { effort: "high" }` to keep the previous depth. It also rejects `thinking: true` and `thinking: { budget_tokens: }` (as Opus 5 already does) and `temperature`.

## 3.7.0

### Added

- Opt-in prompt caching via `cache: true` (5-minute TTL) or `cache: { ttl: "1h" }`. Marks the system prompt (or the last tool, when there is no system prompt) and the last block of the last message with `cache_control`. Off by default; with it off the payload is unchanged.

### Changed

- `OmniAI::Chat::Usage#input_tokens` now includes `cache_creation_input_tokens` and `cache_read_input_tokens`, so it reports the whole prompt as for other providers. Anthropic's own `input_tokens` excludes cached tokens. Without caching both are zero and the value is unchanged. The cache breakdown remains on `response.data["usage"]`.

  **If you price from `input_tokens`, you will bill cached tokens at the full input rate and measure zero improvement from caching.** Price cache reads and writes from `cache_read_input_tokens` and `cache_creation_input_tokens` (per TTL: `cache_creation.ephemeral_5m_input_tokens` / `ephemeral_1h_input_tokens`) and subtract them from `input_tokens`.

## 3.6.0

### Added

- `OmniAI::Chat::Usage#thinking_tokens` is now populated from `usage.output_tokens_details.thinking_tokens` via a new `:usage` deserializer registered on the Anthropic context. Reasoning spend was previously unreadable through this gem. Requires omniai >= 3.8.

  Anthropic already counts reasoning inside `output_tokens`, so this reports the breakdown without changing the output total. `thinking_tokens` is a subset, not an addition — adding it to `output_tokens` double counts.

### Fixed

- Streamed responses now carry `usage.output_tokens_details` through to the assembled payload, surfacing as `OmniAI::Chat::Usage#thinking_tokens`. The stream merged only `input_tokens` and `output_tokens` out of each `message_delta`, and Anthropic sends the reasoning breakdown only on the final one, so it was dropped on every streamed response — leaving streamed responses reporting no reasoning while non-streamed ones reported it. Requires omniai >= 3.8.

  Anthropic already counts reasoning inside `output_tokens`, so this adds the breakdown without changing the output total. Do not add `thinking_tokens` to `output_tokens` yourself — it is a subset, not an addition.

## 3.5.0

### Added

- `OmniAI::Anthropic::Chat::Model::CLAUDE_OPUS_5` (`"claude-opus-5"`).
- `OmniAI::Anthropic::Chat::Model::CLAUDE_FABLE_5` (`"claude-fable-5"`).

### Changed

- The generic `CLAUDE_OPUS` alias now points to `CLAUDE_OPUS_5` (was `CLAUDE_OPUS_4_7`). `DEFAULT_MODEL` follows `CLAUDE_SONNET`, not `CLAUDE_OPUS`, so the provider default is unchanged (`claude-sonnet-5`); this only affects callers passing `Model::CLAUDE_OPUS` explicitly. Pin `CLAUDE_OPUS_4_7` to keep the previous model.

## 3.4.1

### Fixed

- `thinking: { effort:, display: }` now forwards `display` onto the adaptive thinking object (`{ type: "adaptive", display: ... }`). Previously the adaptive branch returned a bare `{ type: "adaptive" }` and silently dropped `:display`, so callers could not opt into summarized thinking on models that default `display` to `"omitted"` (Sonnet 5, Opus 4.7+). `display` remains strictly opt-in: when omitted, no `display` key is sent and the model's own default applies.

  Known limitation: `:display` is only honored on the adaptive branch (reached by passing the `:effort` key). Passing `display` without `effort` falls through to enabled mode and is out of scope for this fix.

## 3.4.0

### Added

- `OmniAI::Anthropic::Chat::Model::CLAUDE_SONNET_5` (`"claude-sonnet-5"`).

### Changed

- The generic `CLAUDE_SONNET` alias now points to `CLAUDE_SONNET_5` (was `CLAUDE_SONNET_4_6`). Since `DEFAULT_MODEL` follows `CLAUDE_SONNET`, the provider default is now `claude-sonnet-5`. Pin `CLAUDE_SONNET_4_6` explicitly to keep the previous model.

## 3.3.0

### Added

- `OmniAI::Chat::Response#finish_reason` (and the per-choice `finish_reason`) are now populated from the Anthropic `stop_reason` as a normalized `OmniAI::Chat::FinishReason`: `end_turn`/`stop_sequence` → `:stop`, `max_tokens` → `:length`, `tool_use` → `:tool_call`, `refusal` → `:filter` (`pause_turn` and any unrecognized value → `:other`). The verbatim `stop_reason` is preserved as `finish_reason.value`. Works for both non-streaming and streaming responses. Requires omniai >= 3.7.

## 3.2.1

### Fixed

- Per-call `max_tokens:` kwarg now flows through to the Anthropic payload on the adaptive thinking path. Previously the kwarg was silently dropped because `payload` only consulted `thinking_max_tokens`, which returned nil for adaptive mode.
- Adaptive thinking calls with no explicit `max_tokens:` now enforce a safe floor (32_768 tokens) to prevent empty responses caused by extended thinking consuming the entire output budget.
