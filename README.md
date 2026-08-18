# Nerve

Nerve is a pluggable in-app debug console for Flutter apps.

It is designed for teams that need more than an HTTP log viewer: network
diagnostics, environment information, device and app state, connectivity checks,
feature flags, and product-specific debug panels can all live behind one safe
debug launcher.

## Status

This repository is an early v0.1 scaffold. It is ready for local evaluation and
Git-based integration, but it is not prepared for pub.dev publishing yet.

## Packages

- `nerve_core`: plugin contracts, summaries, diagnostics export, and redaction.
- `nerve_flutter`: Flutter overlay launcher and debug console UI.
- `nerve_network_ninja`: adapter for `network_ninja` using public APIs only.
- `nerve_wen_adapter`: Wen Wallet adapter example; not intended for public
  package publishing.
- `example`: minimal Flutter demo app.

## Design Goals

- Keep the debug framework independent from business apps.
- Treat network logging as one plugin, not the whole product.
- Never import third-party `src/` implementation files.
- Redact tokens, cookies, signatures, wallet secrets, mnemonics, and private
  keys before diagnostics are displayed or exported.
- Make dangerous actions explicit opt-ins. Runtime environment switching, token
  clearing, cache clearing, and WebSocket resets are intentionally not part of
  v0.1.

## Quick Start

Add the packages by Git path or local path during early development:

```yaml
dependencies:
  nerve_core:
    git:
      url: git@github.com:YOUR_ORG/flutter_nerve.git
      path: packages/nerve_core
  nerve_flutter:
    git:
      url: git@github.com:YOUR_ORG/flutter_nerve.git
      path: packages/nerve_flutter
  nerve_network_ninja:
    git:
      url: git@github.com:YOUR_ORG/flutter_nerve.git
      path: packages/nerve_network_ninja
```

Wrap your app and register plugins:

```dart
final dio = Dio();
final networkAdapter = NerveNetworkNinjaAdapter()..attachTo(dio);

final controller = DebugHubController()
  ..registerPlugin(networkAdapter.plugin)
  ..registerPlugin(
    const EnvironmentDebugPlugin(
      env: 'dev',
      hosts: {
        'api': 'https://api.example.com',
        'ws': 'wss://ws.example.com',
      },
    ),
  )
  ..registerPlugin(
    FlagsDebugPlugin({
      'ENABLE_DEVTOOL': const bool.fromEnvironment('ENABLE_DEVTOOL'),
    }),
  );

MaterialApp(
  builder: (context, child) => DebugHubOverlayHost(
    enabled: const bool.fromEnvironment('ENABLE_DEVTOOL'),
    controller: controller,
    launchPluginId: 'network',
    pluginPages: {
      'network': (context, actions) => NerveNetworkLogsPage(actions: actions),
    },
    child: child ?? const SizedBox.shrink(),
  ),
);
```

`NerveNetworkLogsPage` is Nerve's own network log UI. It reads captured logs
through the public `network_ninja` API and does not import third-party
`src/screens` or `src/widgets`.

## Development

```bash
flutter pub get
dart test packages/nerve_core/test
flutter test packages/nerve_flutter/test
flutter test packages/nerve_network_ninja/test
dart test packages/nerve_wen_adapter/test
flutter test example/test
dart analyze
```

## Wen Wallet Integration Direction

Wen Wallet should depend on Nerve from Git and keep Wen-specific wiring in an
adapter layer. The app should pass environment, host, connectivity endpoints,
and product-specific panels into Nerve. Nerve core packages should not hard-code
Wen hosts, routes, user objects, or wallet data.

## License

MIT
