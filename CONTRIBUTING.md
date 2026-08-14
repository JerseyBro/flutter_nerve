# Contributing

Nerve is intentionally small in v0.1. Contributions should keep the core
framework independent from any single product.

## Rules

- Do not add product secrets, tokens, wallet objects, mnemonics, or private keys
  to examples, tests, logs, or documentation.
- Do not import another package's `src/` files.
- Keep dangerous debug actions behind explicit opt-in APIs.
- Add tests for plugin contracts, redaction, diagnostics export, and UI behavior.
- Run `dart analyze` and the package tests before opening a pull request.

## Package Boundaries

- `nerve_core` must stay Flutter-free.
- `nerve_flutter` can depend on Flutter and `nerve_core`.
- Adapter packages may depend on third-party debug tools.
- Product-specific adapters should not leak product details into core packages.

