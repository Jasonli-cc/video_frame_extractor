package com.chanwind.video_frame_extractor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.MediaMetadataRetriever
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaCodec
import android.net.Uri
import android.os.Handler
import android.os.Looper
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** VideoFrameExtractorPlugin */
class VideoFrameExtractorPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_frame_extractor")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getFrame" -> {
        val filePath = call.argument<String>("filePath")
        val second = call.argument<Double>("second")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val format = call.argument<String>("format") ?: "png"
        val quality = call.argument<Int>("quality") ?: 90
        val exactTime = call.argument<Boolean>("exactTime") ?: false

        if (filePath == null || second == null || second < 0) {
          result.error("invalid_args", "filePath or second is invalid", null)
          return
        }

        Thread {
          val handler = Handler(Looper.getMainLooper())
          val retriever = MediaMetadataRetriever()
          try {
            if (filePath.startsWith("content://")) {
              retriever.setDataSource(context, Uri.parse(filePath))
            } else {
              retriever.setDataSource(filePath)
            }
            val timeUs = (second * 1_000_000L).toLong()
            val option = if (exactTime) MediaMetadataRetriever.OPTION_CLOSEST_SYNC else MediaMetadataRetriever.OPTION_CLOSEST
            val frame = retriever.getFrameAtTime(timeUs, option)
            if (frame == null) {
              handler.post { result.error("decode_failed", "failed to get frame", null) }
              return@Thread
            }
            var bmp: Bitmap = frame
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            if (rotation != 0) {
              val matrix = Matrix()
              matrix.postRotate(rotation.toFloat())
              bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
            }
            if (width != null || height != null) {
              val targetW = width ?: (height?.let { (bmp.width * it) / bmp.height } ?: bmp.width)
              val targetH = height ?: (width?.let { (bmp.height * it) / bmp.width } ?: bmp.height)
              val scaled = Bitmap.createScaledBitmap(bmp, targetW, targetH, true)
              bmp.recycle()
              bmp = scaled
            }
            val stream = ByteArrayOutputStream()
            val compressFormat = if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG
            val q = if (compressFormat == Bitmap.CompressFormat.JPEG) quality.coerceIn(0, 100) else 100
            bmp.compress(compressFormat, q, stream)
            val bytes = stream.toByteArray()
            stream.close()
            bmp.recycle()
            handler.post { result.success(bytes) }
          } catch (e: Exception) {
            handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
          } finally {
            try { retriever.release() } catch (_: Exception) {}
          }
        }.start()
      }
      "getFrames" -> {
        val filePath = call.argument<String>("filePath")
        val seconds = call.argument<List<Double>>("seconds")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val format = call.argument<String>("format") ?: "jpeg"
        val quality = call.argument<Int>("quality") ?: 85
        val exactTime = call.argument<Boolean>("exactTime") ?: false
        val applyRotation = call.argument<Boolean>("applyRotation") ?: true

        if (filePath == null || seconds == null || seconds.isEmpty()) {
          result.error("invalid_args", "filePath or seconds is invalid", null)
          return
        }

        Thread {
          val handler = Handler(Looper.getMainLooper())
          val retriever = MediaMetadataRetriever()
          try {
            if (filePath.startsWith("content://")) {
              retriever.setDataSource(context, Uri.parse(filePath))
            } else {
              retriever.setDataSource(filePath)
            }
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val option = if (exactTime) MediaMetadataRetriever.OPTION_CLOSEST_SYNC else MediaMetadataRetriever.OPTION_CLOSEST
            val out = ArrayList<ByteArray?>(seconds.size)
            for (sec in seconds) {
              if (sec == null || sec < 0) {
                out.add(null)
                continue
              }
              val timeUs = (sec * 1_000_000L).toLong()
              val frame = retriever.getFrameAtTime(timeUs, option)
              if (frame == null) {
                out.add(null)
                continue
              }
              var bmp: Bitmap = frame
              if (applyRotation && rotation != 0) {
                val matrix = Matrix()
                matrix.postRotate(rotation.toFloat())
                bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
              }
              if (width != null || height != null) {
                val targetW = width ?: (height?.let { (bmp.width * it) / bmp.height } ?: bmp.width)
                val targetH = height ?: (width?.let { (bmp.height * it) / bmp.width } ?: bmp.height)
                val scaled = Bitmap.createScaledBitmap(bmp, targetW, targetH, true)
                bmp.recycle()
                bmp = scaled
              }
              val stream = ByteArrayOutputStream(1024 * 64)
              val compressFormat = if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG
              val q = if (compressFormat == Bitmap.CompressFormat.JPEG) quality.coerceIn(0, 100) else 100
              bmp.compress(compressFormat, q, stream)
              val bytes = stream.toByteArray()
              stream.close()
              bmp.recycle()
              out.add(bytes)
            }
            handler.post { result.success(out) }
          } catch (e: Exception) {
            handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
          } finally {
            try { retriever.release() } catch (_: Exception) {}
          }
        }.start()
      }
      "getFramesBytes" -> {
        val filePath = call.argument<String>("filePath")
        val seconds = call.argument<List<Double>>("seconds")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val format = call.argument<String>("format") ?: "jpeg"
        val quality = call.argument<Int>("quality") ?: 85
        val exactTime = call.argument<Boolean>("exactTime") ?: false
        val applyRotation = call.argument<Boolean>("applyRotation") ?: true
        val modeAndroid = call.argument<String>("modeAndroid") ?: "default"
        if (filePath == null || seconds == null || seconds.isEmpty()) {
          result.error("invalid_args", "filePath or seconds is invalid", null)
          return
        }
        Thread {
          val handler = Handler(Looper.getMainLooper())
          try {
            if (modeAndroid.lowercase(Locale.ROOT) == "codec") {
              val list = decodeWithCodecToBytes(filePath, seconds, width, height, format, quality, applyRotation)
              handler.post { result.success(list) }
            } else {
              // fallback to retriever path
              val retriever = MediaMetadataRetriever()
              try {
                if (filePath.startsWith("content://")) retriever.setDataSource(context, Uri.parse(filePath)) else retriever.setDataSource(filePath)
                val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                val option = if (exactTime) MediaMetadataRetriever.OPTION_CLOSEST_SYNC else MediaMetadataRetriever.OPTION_CLOSEST
                val out = ArrayList<ByteArray?>(seconds.size)
                for (sec in seconds) {
                  if (sec == null || sec < 0) { out.add(null); continue }
                  val timeUs = (sec * 1_000_000L).toLong()
                  val frame = retriever.getFrameAtTime(timeUs, option)
                  if (frame == null) { out.add(null); continue }
                  var bmp: Bitmap = frame
                  if (applyRotation && rotation != 0) {
                    val matrix = Matrix(); matrix.postRotate(rotation.toFloat()); bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
                  }
                  if (width != null || height != null) {
                    val targetW = width ?: (height?.let { (bmp.width * it) / bmp.height } ?: bmp.width)
                    val targetH = height ?: (width?.let { (bmp.height * it) / bmp.width } ?: bmp.height)
                    val scaled = Bitmap.createScaledBitmap(bmp, targetW, targetH, true); bmp.recycle(); bmp = scaled
                  }
                  val stream = ByteArrayOutputStream(1024 * 64)
                  val compressFormat = if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG
                  val q = if (compressFormat == Bitmap.CompressFormat.JPEG) quality.coerceIn(0, 100) else 100
                  bmp.compress(compressFormat, q, stream)
                  val bytes = stream.toByteArray(); stream.close(); bmp.recycle(); out.add(bytes)
                }
                handler.post { result.success(out) }
              } catch (e: Exception) {
                handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
              } finally { try { retriever.release() } catch (_: Exception) {} }
            }
          } catch (e: Exception) {
            handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
          }
        }.start()
      }
      "getFramesToFiles" -> {
        val filePath = call.argument<String>("filePath")
        val seconds = call.argument<List<Double>>("seconds")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val format = call.argument<String>("format") ?: "jpeg"
        val quality = call.argument<Int>("quality") ?: 85
        val exactTime = call.argument<Boolean>("exactTime") ?: false
        val applyRotation = call.argument<Boolean>("applyRotation") ?: true
        val cacheDirArg = call.argument<String>("cacheDir")
        val cachePolicy = call.argument<String>("cachePolicy") ?: "use"
        val modeAndroid = call.argument<String>("modeAndroid") ?: "default"
        if (filePath == null || seconds == null || seconds.isEmpty()) {
          result.error("invalid_args", "filePath or seconds is invalid", null)
          return
        }
        Thread {
          val handler = Handler(Looper.getMainLooper())
          try {
            val baseDir = File(cacheDirArg ?: context.cacheDir.absolutePath)
            val subDir = File(baseDir, "video_frame_extractor"); if (!subDir.exists()) subDir.mkdirs()
            val baseName = File(filePath).name
            val out = ArrayList<String?>(seconds.size)
            val useCodec = modeAndroid.lowercase(Locale.ROOT) == "codec"
            // helper: write bytes or reuse
            fun writeOrReuse(sec: Double, index: Int, provider: () -> ByteArray?): String? {
              val name = "vf_${baseName}_${sec}_${width ?: 0}x${height ?: 0}_${format}_${quality}_${if (applyRotation) 1 else 0}." + (if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") "jpg" else "png")
              val file = File(subDir, name)
              if (cachePolicy == "use" && file.exists()) return file.absolutePath
              val bytes = provider() ?: return null
              FileOutputStream(file).use { it.write(bytes) }
              return file.absolutePath
            }
            if (useCodec) {
              val bytesList = decodeWithCodecToBytes(filePath, seconds, width, height, format, quality, applyRotation)
              for ((i, sec) in seconds.withIndex()) {
                val path = writeOrReuse(sec, i) { bytesList[i] }
                out.add(path)
              }
            } else {
              val retriever = MediaMetadataRetriever()
              try {
                if (filePath.startsWith("content://")) retriever.setDataSource(context, Uri.parse(filePath)) else retriever.setDataSource(filePath)
                val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                val option = if (exactTime) MediaMetadataRetriever.OPTION_CLOSEST_SYNC else MediaMetadataRetriever.OPTION_CLOSEST
                for ((i, sec) in seconds.withIndex()) {
                  if (sec < 0) { out.add(null); continue }
                  val timeUs = (sec * 1_000_000L).toLong()
                  val frame = retriever.getFrameAtTime(timeUs, option)
                  if (frame == null) { out.add(null); continue }
                  var bmp: Bitmap = frame
                  if (applyRotation && rotation != 0) { val m = Matrix(); m.postRotate(rotation.toFloat()); bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true) }
                  if (width != null || height != null) { val tw = width ?: (height?.let { (bmp.width * it) / bmp.height } ?: bmp.width); val th = height ?: (width?.let { (bmp.height * it) / bmp.width } ?: bmp.height); val scaled = Bitmap.createScaledBitmap(bmp, tw, th, true); bmp.recycle(); bmp = scaled }
                  val stream = ByteArrayOutputStream(1024 * 64); val cf = if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG; val q = if (cf == Bitmap.CompressFormat.JPEG) quality.coerceIn(0, 100) else 100; bmp.compress(cf, q, stream); val bytes = stream.toByteArray(); stream.close(); bmp.recycle()
                  val path = writeOrReuse(sec, i) { bytes }
                  out.add(path)
                }
              } catch (e: Exception) {
                handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
                return@Thread
              } finally { try { retriever.release() } catch (_: Exception) {} }
            }
            handler.post { result.success(out) }
          } catch (e: Exception) {
            handler.post { result.error("internal_error", e.message ?: "unknown error", null) }
          }
        }.start()
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // Simplified codec pipeline: decode sequential frames and return compressed bytes; fallback ready if unsupported.
  private fun decodeWithCodecToBytes(
    filePath: String,
    seconds: List<Double>,
    width: Int?,
    height: Int?,
    format: String,
    quality: Int,
    applyRotation: Boolean,
  ): List<ByteArray?> {
    // For first iteration, to keep complexity manageable and compatibility broad,
    // we fall back to retriever under the hood. Replace with real MediaCodec pipeline in follow-up.
    val retriever = MediaMetadataRetriever()
    try {
      if (filePath.startsWith("content://")) retriever.setDataSource(context, Uri.parse(filePath)) else retriever.setDataSource(filePath)
      val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
      val option = MediaMetadataRetriever.OPTION_CLOSEST
      val out = ArrayList<ByteArray?>(seconds.size)
      for (sec in seconds) {
        if (sec < 0) { out.add(null); continue }
        val timeUs = (sec * 1_000_000L).toLong()
        val frame = retriever.getFrameAtTime(timeUs, option)
        if (frame == null) { out.add(null); continue }
        var bmp: Bitmap = frame
        if (applyRotation && rotation != 0) { val m = Matrix(); m.postRotate(rotation.toFloat()); bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true) }
        if (width != null || height != null) { val tw = width ?: (height?.let { (bmp.width * it) / bmp.height } ?: bmp.width); val th = height ?: (width?.let { (bmp.height * it) / bmp.width } ?: bmp.height); val scaled = Bitmap.createScaledBitmap(bmp, tw, th, true); bmp.recycle(); bmp = scaled }
        val stream = ByteArrayOutputStream(1024 * 64); val cf = if (format.lowercase() == "jpeg" || format.lowercase() == "jpg") Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG; val q = if (cf == Bitmap.CompressFormat.JPEG) quality.coerceIn(0, 100) else 100; bmp.compress(cf, q, stream); val bytes = stream.toByteArray(); stream.close(); bmp.recycle(); out.add(bytes)
      }
      return out
    } catch (_: Exception) {
      return List(seconds.size) { null }
    } finally { try { retriever.release() } catch (_: Exception) {} }
  }
}
