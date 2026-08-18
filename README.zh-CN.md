# Nerve

Nerve 是一个 Flutter App 内置调试控制台。

它不是单纯的网络日志库，而是一个可插拔 Debug 中枢：网络日志、环境信息、
设备状态、连通性诊断、启动参数和业务自定义调试面板都可以挂到同一个入口。

## 当前状态

当前是 v0.1 Git 依赖接入版本，已包含可用的网络日志页；暂不作为 pub.dev 发布版本。

## 包结构

- `nerve_core`：插件协议、摘要模型、诊断导出和脱敏。
- `nerve_flutter`：Flutter 悬浮入口和调试面板 UI。
- `nerve_network_ninja`：基于 `network_ninja` 公开 API 的采集适配和 Nerve 网络日志 UI。
- `nerve_wen_adapter`：Wen Wallet 接入示例，不作为公开包发布。
- `example`：最小 Flutter 示例 App。

## 设计边界

- Nerve 独立于业务 App 维护，Wen 只是引用方。
- 网络日志只是一个插件，不是整个产品。
- 不引用第三方包的 `src/` 私有实现。
- 导出或展示诊断信息前必须脱敏 token、cookie、签名、钱包密钥、助记词和私钥。
- v0.1 不做运行时切环境、清 token、清缓存、重建 Dio、断开 WS 等危险动作。

## Wen 接入方向

Wen Wallet 后续只在接线层依赖 Nerve：

- 用 `DebugHubOverlayHost` 替换当前内部浮球 Host。
- 用 `NerveNetworkNinjaAdapter` 接入 Dio 网络日志。
- 用 `NerveNetworkLogsPage` 作为网络日志详情页，不再依赖 `network_ninja/src` 私有 UI。
- Wen 自己传入 env、API host、WS host、MPC host、连通性测试 endpoint 和业务面板。
- Nerve 核心包不写死 Wen 域名、路由、用户对象或钱包数据。

## 本地验证

```bash
flutter pub get
dart test packages/nerve_core/test
flutter test packages/nerve_flutter/test
flutter test packages/nerve_network_ninja/test
dart test packages/nerve_wen_adapter/test
flutter test example/test
dart analyze
```

## License

MIT
