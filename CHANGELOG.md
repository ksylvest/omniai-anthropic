# Changelog

## 3.3.0

### Added

- `OmniAI::Chat::Response#finish_reason` (and the per-choice `finish_reason`) are now populated from the Anthropic `stop_reason` as a normalized `OmniAI::Chat::FinishReason`: `end_turn`/`stop_sequence` → `:stop`, `max_tokens` → `:length`, `tool_use` → `:tool_call`, `refusal` → `:filter` (`pause_turn` and any unrecognized value → `:other`). The verbatim `stop_reason` is preserved as `finish_reason.value`. Works for both non-streaming and streaming responses. Requires omniai >= 3.7.

## 3.2.1

### Fixed

- Per-call `max_tokens:` kwarg now flows through to the Anthropic payload on the adaptive thinking path. Previously the kwarg was silently dropped because `payload` only consulted `thinking_max_tokens`, which returned nil for adaptive mode.
- Adaptive thinking calls with no explicit `max_tokens:` now enforce a safe floor (32_768 tokens) to prevent empty responses caused by extended thinking consuming the entire output budget.
