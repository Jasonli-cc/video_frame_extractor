## 目标
- 将“数据返回”和“文件返回”拆分为两个清晰接口，提升易用性与扩展性。
- 引入可配置的缓存策略：在文件返回接口中校验本地缓存，存在则直接返回；按策略可选择覆盖刷新。
- 保持既有批量优化（Android Codec、iOS 异步）的设计不变，在新接口下无缝使用。

## Dart API 设计
- 数据接口（返回字节）
  - `Future<List<Uint8List?>?> getFramesBytes(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async'})`
  - 单帧版本：`Future<Uint8List?> getFrameBytes(...)`（便于调用者统一语义）
- 文件接口（返回路径，内置缓存）
  - `Future<List<String?>?> getFramesToFiles(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async', String? cacheDir, String cachePolicy = 'use'})`
    - `cachePolicy`：
      - `use`（默认）：若缓存存在直接返回；不存在则生成并写入；
      - `refresh`：无视已有缓存，始终重新生成并覆盖写入。
  - 单帧版本：`Future<String?> getFrameToFile(...)`
- 说明：
  - 参数与现有 `getFrames` 基本一致，仅将返回类型与缓存策略抽象出来。
  - `modeAndroid` 与 `modeIOS` 沿用：Android `default|codec`，iOS `default|async`。

## 缓存策略与命名
- 缓存命名采用确定性哈希：基于 `(filePath, second(s), width, height, format, quality, applyRotation)` 生成 SHA-1/MD5 前缀，以避免冲突。
- 文件名示例：`vf_<hash>_<second_index>.jpg|.png`，目录：
  - Android：`context.cacheDir/<plugin-subdir>`（可通过 `cacheDir` 覆盖）
  - iOS：`cachesDirectory/<plugin-subdir>` 或 `NSTemporaryDirectory()`（可通过 `cacheDir` 覆盖）
- `cachePolicy='use'`：存在则直接返回路径；`'refresh'`：先删或覆盖写入。
- 清理策略（后续可选）：提供 `clearCache()` 与按视频路径/哈希清理的 API。

## Android 实现要点（两种接口）
- 数据接口：沿用已实现的批量管线，返回字节列表；`modeAndroid='codec'` 时优先走 `MediaExtractor+MediaCodec` 连续解码，失败回退 `MediaMetadataRetriever`。
- 文件接口：在生成字节后写入缓存路径；按 `cachePolicy` 判定：
  - `use`：若文件存在直接返回；不存在则编码写入
  - `refresh`：总是重新编码并覆盖写入
- 旋转、缩放与编码逻辑与数据接口一致；确保逐帧释放 `Image/Bitmap` 与流，避免内存峰值。

## iOS 实现要点（两种接口）
- 数据接口：默认使用 `generateCGImagesAsynchronously(forTimes:)` 批量异步生成，再编码为 `Data` 返回；`modeIOS='default'` 时保留同步逐帧回退。
- 文件接口：在回调中将 `Data` 写入缓存位置；按 `cachePolicy` 判定是否复用/覆盖；维持返回路径顺序与秒数对应。

## 方法通道与平台接口
- 平台接口新增：
  - `getFramesBytes(...)` 与 `getFrameBytes(...)`
  - `getFramesToFiles(...)` 与 `getFrameToFile(...)`
- MethodChannel：新增方法名 `getFramesBytes`, `getFrameBytes`, `getFramesToFiles`, `getFrameToFile`；分别返回 `List<Uint8List?>` 与 `List<String?>`。
- 向后兼容：保留现有 `getFrames`；建议在文档中标记为“兼容层”，新项目使用拆分接口。

## 测试与验证
- Dart：
  - 通道参数映射与返回类型断言（bytes 与 paths 分别校验顺序与 `null` 占位）。
- Android/iOS：
  - 缓存命中路径：先生成，再调用 `cachePolicy='use'` 验证命中速度；
  - 刷新覆盖：`cachePolicy='refresh'` 验证内容更新；
  - 模式对比：Android `default` vs `codec`；iOS `default` vs `async`。

## 交付顺序
1) Dart 层新增四个接口与参数落地；方法通道与平台接口完善。
2) Android 文件接口实现与缓存策略；数据接口沿用已落地批量逻辑，并开放 `codec` 模式。
3) iOS 文件接口实现与缓存策略；数据接口切换异步批量；保留默认回退。
4) 示例与基准：同一视频 100 帧测试，记录缓存命中与刷新、不同模式对比。

请确认以上方案，我将据此在两端与 Dart 层实现拆分接口与缓存策略，并完成验证与示例更新。