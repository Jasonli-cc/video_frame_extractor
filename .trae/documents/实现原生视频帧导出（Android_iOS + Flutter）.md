## 目标
- 在 Flutter 插件 `video_frame_extractor` 中新增跨平台能力：按“视频文件路径 + 秒数”提取对应视频帧并返回 `Uint8List`（PNG/JPEG）。
- API（Dart 层）形态：`Future<Uint8List?> VideoFrameExtractor.getFrame(String filePath, {double second, int? width, int? height, String format = 'png', int quality = 90, bool exactTime = false})`。

## 现状定位
- Dart 封装类在 `lib/video_frame_extractor.dart:4`，仅有 `getPlatformVersion`（`lib/video_frame_extractor.dart:5`）。
- 渠道在 `lib/video_frame_extractor_method_channel.dart:10`（名称 `video_frame_extractor`），已实现 `getPlatformVersion`（`lib/video_frame_extractor_method_channel.dart:13-16`）。
- Android 插件入口：`android/src/main/kotlin/.../VideoFrameExtractorPlugin.kt:22-28` 仅处理 `getPlatformVersion`。
- iOS 插件入口：`ios/Classes/VideoFrameExtractorPlugin.swift:11-18` 仅处理 `getPlatformVersion`。

## API 设计
- 新增方法：`getFrame`
  - 入参：`filePath`（本地路径或 `content://` URI）、`second`（Double，支持小数）、可选 `width/height`（缩放目标尺寸，等比缩放）、`format`（`png|jpeg`）、`quality`（0-100，仅 JPEG）、`exactTime`（是否强制精确到指定时间）。
  - 出参：`Future<Uint8List?>`，返回编码后的图片字节；错误时抛 `PlatformException`，附带错误码与信息。

## Android 实现
- 使用 `MediaMetadataRetriever`：
  - `setDataSource`：支持两种数据源
    - `content://`：使用 `flutterPluginBinding.applicationContext` 与 `Uri.parse(path)`。
    - 文件路径：直接 `setDataSource(path)`。
  - 时间换算：`timeUs = (second * 1_000_000).toLong()`。
  - 帧获取：`getFrameAtTime(timeUs, option)`，`option` 为：
    - `OPTION_CLOSEST_SYNC` 当 `exactTime == true`，
    - 否则 `OPTION_CLOSEST`。
  - 旋转处理：读取 `METADATA_KEY_VIDEO_ROTATION`，若不为 0，按角度旋转 `Bitmap`。
  - 尺寸缩放：如指定 `width/height`，按等比缩放到目标的最大边（保持纵横比）。
  - 编码：
    - PNG：`Bitmap.CompressFormat.PNG`。
    - JPEG：`Bitmap.CompressFormat.JPEG` + `quality`。
  - 资源释放：`retriever.release()`，异常捕获并通过 `result.error(code, message, details)` 返回。
- 线程：在插件中切到后台线程处理，避免主线程阻塞，完成后回调 `result.success(byteArray)`。

## iOS 实现
- 使用 `AVAssetImageGenerator`：
  - 资源：`AVURLAsset(url:)`，路径支持 `file://` 与普通文件路径。
  - 生成器：`AVAssetImageGenerator(asset)`，设置 `appliesPreferredTrackTransform = true` 以应用视频的旋转与裁剪。
  - 精度：
    - 当 `exactTime == true`：`requestedTimeToleranceBefore/After = .zero`。
    - 否则使用默认容忍度。
  - 时间：`CMTime(seconds: second, preferredTimescale: 600)`。
  - 尺寸：若提供 `width/height`，设置 `maximumSize` 进行等比缩放。
  - 编码：
    - PNG：`pngData()`。
    - JPEG：`jpegData(compressionQuality: quality/100.0)`。
  - 异常捕获并通过 `FlutterError` 返回到 Dart。
- 线程：在后台队列获取帧并编码，完成后切回主线程回调。

## Dart 层实现
- `lib/video_frame_extractor_platform_interface.dart`：新增抽象方法 `Future<Uint8List?> getFrame(...)`。
- `lib/video_frame_extractor_method_channel.dart`：实现 `invokeMethod<Uint8List>('getFrame', args)`，构造参数 Map。
- `lib/video_frame_extractor.dart`：对外暴露静态/实例方法 `getFrame(...)` 并转发到 `VideoFrameExtractorPlatform.instance.getFrame(...)`。
- 说明：平台通道为异步调用，最终返回 `Future<Uint8List?>`；与用户示例的同步写法不同，建议在 Dart 侧使用 `await`。

## 错误与边界
- 路径无效或不可读：抛 `invalid_path`。
- 时间越界（>时长或负数）：抛 `time_out_of_range`。
- 解码失败或不支持的编码：抛 `decode_failed`。
- 通用内部错误：抛 `internal_error`。

## 示例用法
- Dart：
  - `final bytes = await VideoFrameExtractor.getFrame('/storage/emulated/0/Movies/a.mp4', second: 2.5, format: 'jpeg', quality: 85);`
  - 渲染：`Image.memory(bytes)`。

## 测试与验证
- 单元：Dart 侧参数校验与通道调用（mock）。
- 真机/模拟器：
  - Android：本地文件与 `content://`，不同编码（H264/HEVC），旋转视频用例。
  - iOS：不同秒数、精度选项与尺寸缩放。
- 示例 App：在 `example` 中添加按钮加载本地视频并展示帧图。

## 变更清单（文件级）
- Dart：
  - `lib/video_frame_extractor_platform_interface.dart` 新增接口。
  - `lib/video_frame_extractor_method_channel.dart` 新增 `getFrame` 调用。
  - `lib/video_frame_extractor.dart` 对外暴露 `getFrame`。
- Android：
  - `android/src/main/kotlin/.../VideoFrameExtractorPlugin.kt` 处理 `getFrame` 方法、后台线程、图片编码。
- iOS：
  - `ios/Classes/VideoFrameExtractorPlugin.swift` 处理 `getFrame` 方法、后台队列、图片编码。

请确认以上方案与 API 形态，我将据此完成具体实现与示例更新。