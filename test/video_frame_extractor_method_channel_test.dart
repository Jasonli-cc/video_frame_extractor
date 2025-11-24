import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_frame_extractor/video_frame_extractor_method_channel.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVideoFrameExtractor platform = MethodChannelVideoFrameExtractor();
  const MethodChannel channel = MethodChannel('video_frame_extractor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getFrame returns bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getFrame') {
          return bytes;
        }
        return null;
      },
    );
    final res = await platform.getFrame('/path.mp4', second: 1.0);
    expect(res, equals(bytes));
  });

  test('getFrames returns list of bytes', () async {
    final b1 = Uint8List.fromList([1]);
    final b2 = Uint8List.fromList([2]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getFrames') {
          return [b1, null, b2];
        }
        return null;
      },
    );
    final res = await platform.getFrames('/path.mp4', seconds: [0.5, 1.0, 1.5]);
    expect(res, isNotNull);
    expect(res!.length, 3);
    expect(res[0], equals(b1));
    expect(res[1], isNull);
    expect(res[2], equals(b2));
  });

  test('getFramesBytes returns list of bytes', () async {
    final b1 = Uint8List.fromList([9]);
    final b2 = Uint8List.fromList([8]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getFramesBytes') {
          return [b1, b2];
        }
        return null;
      },
    );
    final res = await platform.getFramesBytes('/path.mp4', seconds: [0.5, 1.0]);
    expect(res, isNotNull);
    expect(res!.length, 2);
    expect(res[0], equals(b1));
    expect(res[1], equals(b2));
  });

  test('getFramesToFiles returns list of paths', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getFramesToFiles') {
          return ['/cache/a.jpg', null, '/cache/b.jpg'];
        }
        return null;
      },
    );
    final res = await platform.getFramesToFiles('/p.mp4', seconds: [0.1, 0.2, 0.3]);
    expect(res, isNotNull);
    expect(res!.length, 3);
    expect(res[0], '/cache/a.jpg');
    expect(res[1], isNull);
    expect(res[2], '/cache/b.jpg');
  });
}
