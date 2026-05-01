# Changelog

## 3.2.1

### Fixed

- Per-call `max_tokens:` kwarg now flows through to the Anthropic payload on the adaptive thinking path. Previously the kwarg was silently dropped because `payload` only consulted `thinking_max_tokens`, which returned nil for adaptive mode.
- Adaptive thinking calls with no explicit `max_tokens:` now enforce a safe floor (32_768 tokens) to prevent empty responses caused by extended thinking consuming the entire output budget.
