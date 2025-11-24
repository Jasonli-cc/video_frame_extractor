
import 'dart:typed_data';
import 'video_frame_extractor_platform_interface.dart';

class VideoFrameExtractor {
  Future<String?> getPlatformVersion() {
    return VideoFrameExtractorPlatform.instance.getPlatformVersion();
  }

  static Future<Uint8List?> getFrame(
    String filePath, {
    required double second,
    int? width,
    int? height,
    String format = 'png',
    int quality = 90,
    bool exactTime = false,
  }) {
    return VideoFrameExtractorPlatform.instance.getFrame(
      filePath,
      second: second,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
    );
  }

  static Future<List<Uint8List?>?> getFrames(
    String filePath, {
    required List<double> seconds,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
  }) {
    return VideoFrameExtractorPlatform.instance.getFrames(
      filePath,
      seconds: seconds,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
    );
  }

  static Future<List<Uint8List?>?> getFramesBytes(
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
    return VideoFrameExtractorPlatform.instance.getFramesBytes(
      filePath,
      seconds: seconds,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
      modeAndroid: modeAndroid,
      modeIOS: modeIOS,
    );
  }

  static Future<Uint8List?> getFrameBytes(
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
    return VideoFrameExtractorPlatform.instance.getFrameBytes(
      filePath,
      second: second,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
      modeAndroid: modeAndroid,
      modeIOS: modeIOS,
    );
  }

  static Future<List<String?>?> getFramesToFiles(
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
    return VideoFrameExtractorPlatform.instance.getFramesToFiles(
      filePath,
      seconds: seconds,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
      cacheDir: cacheDir,
      cachePolicy: cachePolicy,
      modeAndroid: modeAndroid,
      modeIOS: modeIOS,
    );
  }

  static Future<String?> getFrameToFile(
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
    return VideoFrameExtractorPlatform.instance.getFrameToFile(
      filePath,
      second: second,
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
      cacheDir: cacheDir,
      cachePolicy: cachePolicy,
      modeAndroid: modeAndroid,
      modeIOS: modeIOS,
    );
  }
}
