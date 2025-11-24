import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_frame_extractor_method_channel.dart';

abstract class VideoFrameExtractorPlatform extends PlatformInterface {
  /// Constructs a VideoFrameExtractorPlatform.
  VideoFrameExtractorPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoFrameExtractorPlatform _instance = MethodChannelVideoFrameExtractor();

  /// The default instance of [VideoFrameExtractorPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoFrameExtractor].
  static VideoFrameExtractorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoFrameExtractorPlatform] when
  /// they register themselves.
  static set instance(VideoFrameExtractorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Uint8List?> getFrame(
    String filePath, {
    required double second,
    int? width,
    int? height,
    String format = 'png',
    int quality = 90,
    bool exactTime = false,
  }) {
    throw UnimplementedError('getFrame() has not been implemented.');
  }

  Future<List<Uint8List?>?> getFrames(
    String filePath, {
    required List<double> seconds,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
  }) {
    throw UnimplementedError('getFrames() has not been implemented.');
  }

  Future<List<Uint8List?>?> getFramesBytes(
    String filePath, {
    required List<double> seconds,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
    String modeAndroid = 'default',
    String modeIOS = 'async',
  }) {
    throw UnimplementedError('getFramesBytes() has not been implemented.');
  }

  Future<Uint8List?> getFrameBytes(
    String filePath, {
    required double second,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
    String modeAndroid = 'default',
    String modeIOS = 'async',
  }) {
    throw UnimplementedError('getFrameBytes() has not been implemented.');
  }

  Future<List<String?>?> getFramesToFiles(
    String filePath, {
    required List<double> seconds,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
    String? cacheDir,
    String cachePolicy = 'use',
    String modeAndroid = 'default',
    String modeIOS = 'async',
  }) {
    throw UnimplementedError('getFramesToFiles() has not been implemented.');
  }

  Future<String?> getFrameToFile(
    String filePath, {
    required double second,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
    String? cacheDir,
    String cachePolicy = 'use',
    String modeAndroid = 'default',
    String modeIOS = 'async',
  }) {
    throw UnimplementedError('getFrameToFile() has not been implemented.');
  }
}
