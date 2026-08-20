# Changelog

## 3.6.0

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
