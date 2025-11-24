import Flutter
import UIKit
import AVFoundation

public class VideoFrameExtractorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_frame_extractor", binaryMessenger: registrar.messenger())
    let instance = VideoFrameExtractorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getFrame":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "arguments missing", details: nil))
        return
      }
      guard let filePath = args["filePath"] as? String, let second = args["second"] as? Double, second >= 0 else {
        result(FlutterError(code: "invalid_args", message: "filePath or second invalid", details: nil))
        return
      }
      let width = args["width"] as? Int
      let height = args["height"] as? Int
      let format = (args["format"] as? String ?? "png").lowercased()
      let quality = args["quality"] as? Int ?? 90
      let exactTime = args["exactTime"] as? Bool ?? false

      DispatchQueue.global(qos: .userInitiated).async {
        let url: URL
        if filePath.hasPrefix("file://") {
          url = URL(string: filePath)!
        } else {
          url = URL(fileURLWithPath: filePath)
        }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let w = width, let h = height {
          generator.maximumSize = CGSize(width: w, height: h)
        } else if let w = width {
          generator.maximumSize = CGSize(width: CGFloat(w), height: CGFloat.greatestFiniteMagnitude)
        } else if let h = height {
          generator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(h))
        }
        if exactTime {
          generator.requestedTimeToleranceBefore = .zero
          generator.requestedTimeToleranceAfter = .zero
        }
        let time = CMTime(seconds: second, preferredTimescale: 600)
        do {
          let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
          let image = UIImage(cgImage: cgImage)
          let data: Data?
          if format == "jpeg" || format == "jpg" {
            let q = min(max(Double(quality)/100.0, 0.0), 1.0)
            data = image.jpegData(compressionQuality: q)
          } else {
            data = image.pngData()
          }
          guard let bytes = data else {
            DispatchQueue.main.async {
              result(FlutterError(code: "encode_failed", message: "failed to encode image", details: nil))
            }
            return
          }
          DispatchQueue.main.async {
            result(FlutterStandardTypedData(bytes: bytes))
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "decode_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    case "getFrames":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "arguments missing", details: nil))
        return
      }
      guard let filePath = args["filePath"] as? String, let seconds = args["seconds"] as? [Double], !seconds.isEmpty else {
        result(FlutterError(code: "invalid_args", message: "filePath or seconds invalid", details: nil))
        return
      }
      let width = args["width"] as? Int
      let height = args["height"] as? Int
      let format = (args["format"] as? String ?? "jpeg").lowercased()
      let quality = args["quality"] as? Int ?? 85
      let exactTime = args["exactTime"] as? Bool ?? false
      let applyRotation = args["applyRotation"] as? Bool ?? true

      DispatchQueue.global(qos: .userInitiated).async {
        let url: URL = filePath.hasPrefix("file://") ? URL(string: filePath)! : URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = applyRotation
        if let w = width, let h = height {
          generator.maximumSize = CGSize(width: w, height: h)
        } else if let w = width {
          generator.maximumSize = CGSize(width: CGFloat(w), height: CGFloat.greatestFiniteMagnitude)
        } else if let h = height {
          generator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(h))
        }
        if exactTime {
          generator.requestedTimeToleranceBefore = .zero
          generator.requestedTimeToleranceAfter = .zero
        }
        var out: [Any] = []
        for sec in seconds {
          if sec < 0 {
            out.append(NSNull())
            continue
          }
          let time = CMTime(seconds: sec, preferredTimescale: 600)
          do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            let data: Data?
            if format == "jpeg" || format == "jpg" {
              let q = min(max(Double(quality)/100.0, 0.0), 1.0)
              data = image.jpegData(compressionQuality: q)
            } else {
              data = image.pngData()
            }
            if let bytes = data {
              out.append(FlutterStandardTypedData(bytes: bytes))
            } else {
              out.append(NSNull())
            }
          } catch {
            out.append(NSNull())
          }
        }
        DispatchQueue.main.async {
          result(out)
        }
      }
    case "getFramesBytes":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "arguments missing", details: nil))
        return
      }
      guard let filePath = args["filePath"] as? String, let seconds = args["seconds"] as? [Double], !seconds.isEmpty else {
        result(FlutterError(code: "invalid_args", message: "filePath or seconds invalid", details: nil))
        return
      }
      let width = args["width"] as? Int
      let height = args["height"] as? Int
      let format = (args["format"] as? String ?? "jpeg").lowercased()
      let quality = args["quality"] as? Int ?? 85
      let exactTime = args["exactTime"] as? Bool ?? false
      let applyRotation = args["applyRotation"] as? Bool ?? true
      let modeIOS = (args["modeIOS"] as? String ?? "async").lowercased()

      DispatchQueue.global(qos: .userInitiated).async {
        let url: URL = filePath.hasPrefix("file://") ? URL(string: filePath)! : URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = applyRotation
        if let w = width, let h = height { generator.maximumSize = CGSize(width: w, height: h) }
        else if let w = width { generator.maximumSize = CGSize(width: CGFloat(w), height: CGFloat.greatestFiniteMagnitude) }
        else if let h = height { generator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(h)) }
        if exactTime { generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero }

        var out: [Any] = Array(repeating: NSNull(), count: seconds.count)
        if modeIOS == "async" {
          let times = seconds.enumerated().map { (idx, sec) in NSValue(time: CMTime(seconds: sec, preferredTimescale: 600)) }
          var remaining = times.count
          generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, resultStatus, error in
            let idx = times.firstIndex(where: { $0.timeValue == requestedTime }) ?? 0
            if let cgImage = cgImage {
              let image = UIImage(cgImage: cgImage)
              let data: Data? = (format == "jpeg" || format == "jpg") ? image.jpegData(compressionQuality: min(max(Double(quality)/100.0, 0.0), 1.0)) : image.pngData()
              if let bytes = data { out[idx] = FlutterStandardTypedData(bytes: bytes) }
            }
            remaining -= 1
            if remaining == 0 {
              DispatchQueue.main.async { result(out) }
            }
          }
        } else {
          for (i, sec) in seconds.enumerated() {
            if sec < 0 { continue }
            let time = CMTime(seconds: sec, preferredTimescale: 600)
            do {
              let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
              let image = UIImage(cgImage: cgImage)
              let data: Data? = (format == "jpeg" || format == "jpg") ? image.jpegData(compressionQuality: min(max(Double(quality)/100.0, 0.0), 1.0)) : image.pngData()
              if let bytes = data { out[i] = FlutterStandardTypedData(bytes: bytes) }
            } catch { /* keep NSNull */ }
          }
          DispatchQueue.main.async { result(out) }
        }
      }
    case "getFramesToFiles":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "arguments missing", details: nil))
        return
      }
      guard let filePath = args["filePath"] as? String, let seconds = args["seconds"] as? [Double], !seconds.isEmpty else {
        result(FlutterError(code: "invalid_args", message: "filePath or seconds invalid", details: nil))
        return
      }
      let width = args["width"] as? Int
      let height = args["height"] as? Int
      let format = (args["format"] as? String ?? "jpeg").lowercased()
      let quality = args["quality"] as? Int ?? 85
      let exactTime = args["exactTime"] as? Bool ?? false
      let applyRotation = args["applyRotation"] as? Bool ?? true
      let cacheDirArg = args["cacheDir"] as? String
      let cachePolicy = (args["cachePolicy"] as? String ?? "use").lowercased()
      let modeIOS = (args["modeIOS"] as? String ?? "async").lowercased()

      DispatchQueue.global(qos: .userInitiated).async {
        let url: URL = filePath.hasPrefix("file://") ? URL(string: filePath)! : URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = applyRotation
        if let w = width, let h = height { generator.maximumSize = CGSize(width: w, height: h) }
        else if let w = width { generator.maximumSize = CGSize(width: CGFloat(w), height: CGFloat.greatestFiniteMagnitude) }
        else if let h = height { generator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(h)) }
        if exactTime { generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero }

        let fm = FileManager.default
        let baseDir: URL = {
          if let c = cacheDirArg { return URL(fileURLWithPath: c) }
          let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
          return caches.appendingPathComponent("video_frame_extractor", isDirectory: true)
        }()
        if !fm.fileExists(atPath: baseDir.path) { try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true) }
        let baseName = URL(fileURLWithPath: filePath).lastPathComponent
        func fileName(_ sec: Double) -> URL {
          let ext = (format == "jpeg" || format == "jpg") ? "jpg" : "png"
          let name = "vf_\(baseName)_\(sec)_\(width ?? 0)x\(height ?? 0)_\(format)_\(quality)_\(applyRotation ? 1 : 0).\(ext)"
          return baseDir.appendingPathComponent(name)
        }

        var out: [String?] = Array(repeating: nil, count: seconds.count)
        if modeIOS == "async" {
          let times = seconds.enumerated().map { (idx, sec) in NSValue(time: CMTime(seconds: sec, preferredTimescale: 600)) }
          var remaining = times.count
          generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, resultStatus, error in
            let idx = times.firstIndex(where: { $0.timeValue == requestedTime }) ?? 0
            let url = fileName(seconds[idx])
            if cachePolicy == "use", fm.fileExists(atPath: url.path) {
              out[idx] = url.path
            } else if let cgImage = cgImage {
              let image = UIImage(cgImage: cgImage)
              let data: Data? = (format == "jpeg" || format == "jpg") ? image.jpegData(compressionQuality: min(max(Double(quality)/100.0, 0.0), 1.0)) : image.pngData()
              if let bytes = data { try? bytes.write(to: url); out[idx] = url.path }
            }
            remaining -= 1
            if remaining == 0 {
              DispatchQueue.main.async { result(out) }
            }
          }
        } else {
          for (i, sec) in seconds.enumerated() {
            let urlOut = fileName(sec)
            if cachePolicy == "use", fm.fileExists(atPath: urlOut.path) { out[i] = urlOut.path; continue }
            let time = CMTime(seconds: sec, preferredTimescale: 600)
            do {
              let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
              let image = UIImage(cgImage: cgImage)
              let data: Data? = (format == "jpeg" || format == "jpg") ? image.jpegData(compressionQuality: min(max(Double(quality)/100.0, 0.0), 1.0)) : image.pngData()
              if let bytes = data { try? bytes.write(to: urlOut); out[i] = urlOut.path }
            } catch { /* keep nil */ }
          }
          DispatchQueue.main.async { result(out) }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
