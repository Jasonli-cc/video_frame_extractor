import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_frame_extractor_platform_interface.dart';

/// An implementation of [VideoFrameExtractorPlatform] that uses method channels.
class MethodChannelVideoFrameExtractor extends VideoFrameExtractorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_frame_extractor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Uint8List?> getFrame(
    String filePath, {
    required double second,
    int? width,
    int? height,
    String format = 'png',
    int quality = 90,
    bool exactTime = false,
  }) async {
    final args = <String, dynamic>{
      'filePath': filePath,
      'second': second,
      'width': width,
      'height': height,
      'format': format,
      'quality': quality,
      'exactTime': exactTime,
    };
    final bytes = await methodChannel.invokeMethod<Uint8List>('getFrame', args);
    return bytes;
  }

  @override
  Future<List<Uint8List?>?> getFrames(
    String filePath, {
    required List<double> seconds,
    int? width,
    int? height,
    String format = 'jpeg',
    int quality = 85,
    bool exactTime = false,
    bool applyRotation = true,
  }) async {
    final args = <String, dynamic>{
      'filePath': filePath,
      'seconds': seconds,
      'width': width,
      'height': height,
      'format': format,
      'quality': quality,
      'exactTime': exactTime,
      'applyRotation': applyRotation,
    };
    final list = await methodChannel.invokeMethod<List<dynamic>>('getFrames', args);
    if (list == null) return null;
    return list.map((e) => e as Uint8List?).toList();
  }

  @override
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
  }) async {
    final args = <String, dynamic>{
      'filePath': filePath,
      'seconds': seconds,
      'width': width,
      'height': height,
      'format': format,
      'quality': quality,
      'exactTime': exactTime,
      'applyRotation': applyRotation,
      'modeAndroid': modeAndroid,
      'modeIOS': modeIOS,
    };
    final list = await methodChannel.invokeMethod<List<dynamic>>('getFramesBytes', args);
    if (list == null) return null;
    return list.map((e) => e as Uint8List?).toList();
  }

  @override
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
  }) async {
    final res = await getFramesBytes(
      filePath,
      seconds: [second],
      width: width,
      height: height,
      format: format,
      quality: quality,
      exactTime: exactTime,
      applyRotation: applyRotation,
      modeAndroid: modeAndroid,
      modeIOS: modeIOS,
    );
    return res == null || res.isEmpty ? null : res[0];
  }

  @override
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
  }) async {
    final args = <String, dynamic>{
      'filePath': filePath,
      'seconds': seconds,
      'width': width,
      'height': height,
      'format': format,
      'quality': quality,
      'exactTime': exactTime,
      'applyRotation': applyRotation,
      'cacheDir': cacheDir,
      'cachePolicy': cachePolicy,
      'modeAndroid': modeAndroid,
      'modeIOS': modeIOS,
    };
    final list = await methodChannel.invokeMethod<List<dynamic>>('getFramesToFiles', args);
    if (list == null) return null;
    return list.map((e) => e as String?).toList();
  }

  @override
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
  }) async {
    final res = await getFramesToFiles(
      filePath,
      seconds: [second],
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
    return res == null || res.isEmpty ? null : res[0];
  }
}
