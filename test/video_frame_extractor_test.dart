import 'package:flutter_test/flutter_test.dart';
import 'package:video_frame_extractor/video_frame_extractor.dart';
import 'package:video_frame_extractor/video_frame_extractor_platform_interface.dart';
import 'package:video_frame_extractor/video_frame_extractor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

class MockVideoFrameExtractorPlatform
    with MockPlatformInterfaceMixin
    implements VideoFrameExtractorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List?> getFrame(String filePath, {required double second, int? width, int? height, String format = 'png', int quality = 90, bool exactTime = false}) {
    return Future.value(Uint8List.fromList([4, 5, 6]));
  }

  @override
  Future<List<Uint8List?>?> getFrames(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true}) {
    return Future.value(List<Uint8List?>.filled(seconds.length, Uint8List.fromList([4, 5, 6])));
  }

  @override
  Future<List<Uint8List?>?> getFramesBytes(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async'}) {
    return Future.value(List<Uint8List?>.filled(seconds.length, Uint8List.fromList([7])));
  }

  @override
  Future<Uint8List?> getFrameBytes(String filePath, {required double second, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async'}) {
    return Future.value(Uint8List.fromList([8]));
  }

  @override
  Future<List<String?>?> getFramesToFiles(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String? cacheDir, String cachePolicy = 'use', String modeAndroid = 'default', String modeIOS = 'async'}) {
    return Future.value(List<String?>.filled(seconds.length, '/p.jpg'));
  }

  @override
  Future<String?> getFrameToFile(String filePath, {required double second, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String? cacheDir, String cachePolicy = 'use', String modeAndroid = 'default', String modeIOS = 'async'}) {
    return Future.value('/p1.jpg');
  }
}

class MockSplitPlatform with MockPlatformInterfaceMixin implements VideoFrameExtractorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('x');
  @override
  Future<Uint8List?> getFrame(String filePath, {required double second, int? width, int? height, String format = 'png', int quality = 90, bool exactTime = false}) => Future.value(Uint8List.fromList([1]));
  @override
  Future<List<Uint8List?>?> getFrames(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true}) => Future.value([Uint8List.fromList([2])]);
  @override
  Future<List<Uint8List?>?> getFramesBytes(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async'}) => Future.value([Uint8List.fromList([3]), null]);
  @override
  Future<Uint8List?> getFrameBytes(String filePath, {required double second, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String modeAndroid = 'default', String modeIOS = 'async'}) => Future.value(Uint8List.fromList([4]));
  @override
  Future<List<String?>?> getFramesToFiles(String filePath, {required List<double> seconds, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String? cacheDir, String cachePolicy = 'use', String modeAndroid = 'default', String modeIOS = 'async'}) => Future.value(['/p1.jpg', null]);
  @override
  Future<String?> getFrameToFile(String filePath, {required double second, int? width, int? height, String format = 'jpeg', int quality = 85, bool exactTime = false, bool applyRotation = true, String? cacheDir, String cachePolicy = 'use', String modeAndroid = 'default', String modeIOS = 'async'}) => Future.value('/p2.jpg');
}

void main() {
  final VideoFrameExtractorPlatform initialPlatform = VideoFrameExtractorPlatform.instance;

  test('$MethodChannelVideoFrameExtractor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoFrameExtractor>());
  });

  test('getPlatformVersion', () async {
    VideoFrameExtractor videoFrameExtractorPlugin = VideoFrameExtractor();
    MockVideoFrameExtractorPlatform fakePlatform = MockVideoFrameExtractorPlatform();
    VideoFrameExtractorPlatform.instance = fakePlatform;

    expect(await videoFrameExtractorPlugin.getPlatformVersion(), '42');
  });

  test('getFrame', () async {
    MockVideoFrameExtractorPlatform fakePlatform = MockVideoFrameExtractorPlatform();
    VideoFrameExtractorPlatform.instance = fakePlatform;
    final bytes = await VideoFrameExtractor.getFrame('/path.mp4', second: 2.0);
    expect(bytes, isNotNull);
    expect(bytes, equals(Uint8List.fromList([4, 5, 6])));
  });

  test('getFrames', () async {
    MockVideoFrameExtractorPlatform fakePlatform = MockVideoFrameExtractorPlatform();
    VideoFrameExtractorPlatform.instance = fakePlatform;
    final list = await VideoFrameExtractor.getFrames('/path.mp4', seconds: [0.5, 1.0]);
    expect(list, isNotNull);
    expect(list!.length, 2);
    expect(list[0], equals(Uint8List.fromList([4, 5, 6])));
    expect(list[1], equals(Uint8List.fromList([4, 5, 6])));
  });

  test('split APIs getFramesBytes/getFrameBytes/getFramesToFiles/getFrameToFile', () async {
    final fake = MockSplitPlatform();
    VideoFrameExtractorPlatform.instance = fake;
    final bytesList = await VideoFrameExtractor.getFramesBytes('/v.mp4', seconds: [0.1, 0.2]);
    expect(bytesList, isNotNull);
    expect(bytesList![0], isNotNull);
    final oneBytes = await VideoFrameExtractor.getFrameBytes('/v.mp4', second: 0.1);
    expect(oneBytes, isNotNull);
    final paths = await VideoFrameExtractor.getFramesToFiles('/v.mp4', seconds: [0.1, 0.2]);
    expect(paths, isNotNull);
    expect(paths![0], '/p1.jpg');
    final onePath = await VideoFrameExtractor.getFrameToFile('/v.mp4', second: 0.1);
    expect(onePath, '/p2.jpg');
  });
}
