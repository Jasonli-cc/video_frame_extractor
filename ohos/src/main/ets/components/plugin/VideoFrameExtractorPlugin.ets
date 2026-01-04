import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  Log
} from '@ohos/flutter_ohos';

import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';


const TAG = "VideoFrameExtractorPlugin";

/** VideoFrameExtractorPlugin **/
export default class VideoFrameExtractorPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "VideoFrameExtractorPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "video_frame_extractor");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.i(TAG, `onMethodCall ${call.method} ${call.argument}`)
    switch (call.method) {
      case "getPlatformVersion":
        result.success("OHOS")
        break
      case "getFrame":
        this.handleGetFrame(call, result)
        break
      case "getFrames":
        this.handleGetFrames(call, result)
        break
      case "getFramesBytes":
        this.handleGetFramesBytes(call, result)
        break
      case "getFrameBytes":
        this.handleGetFrameBytes(call, result)
        break
      case "getFramesToFiles":
        this.handleGetFramesToFiles(call, result)
        break
      case "getFrameToFile":
        this.handleGetFrameToFile(call, result)
        break
      default:
        result.notImplemented()
    }
  }

  private async handleGetFrame(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const second: number = call.argument("second") as number
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean

      const pixelMap = await this.extractFrame(filePath, second, width, height)
      if (!pixelMap) {
        result.error('GET_FRAME_ERROR', "pixelMap is null", null)
        return
      }

      const bytes = await this.pixelMapToBytes(pixelMap!, format, quality)
      result.success(bytes)
    } catch (error) {
      Log.e(TAG, error.toString())
      result.error('GET_FRAME_ERROR', error.toString(), null)
    }
  }

  private async handleGetFrames(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const seconds: number[] = call.argument("seconds") as number[]
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean

      const frames: Uint8Array[] = []
      for (const second of seconds) {
        const pixelMap = await this.extractFrame(filePath, second, width, height)
        if (pixelMap) {
          const bytes = await this.pixelMapToBytes(pixelMap, format, quality)
          if (bytes) {
            frames.push(bytes)
          } else {
            frames.push(new Uint8Array(0))
          }
        } else {
          frames.push(new Uint8Array(0))
        }
      }
      result.success(frames)
    } catch (error) {
      Log.e(TAG, error.toString())
      result.error('GET_FRAMES_ERROR', error.toString(), null)
    }
  }

  private async handleGetFramesBytes(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const seconds: number[] = call.argument("seconds") as number[]
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean

      const frames: Uint8Array[] = []
      for (const second of seconds) {
        const pixelMap = await this.extractFrame(filePath, second, width, height)
        if (pixelMap) {
          const bytes = await this.pixelMapToBytes(pixelMap, format, quality)
          if (bytes) {
            frames.push(bytes)
          } else {
            frames.push(new Uint8Array(0))
          }
        } else {
          frames.push(new Uint8Array(0))
        }
      }
      result.success(frames)
    } catch (error) {
      Log.e(TAG, error.toString())
      result.error('GET_FRAMES_BYTES_ERROR', error.toString(), null)
    }
  }

  private async handleGetFrameBytes(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const second: number = call.argument("second") as number
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean

      const pixelMap = await this.extractFrame(filePath, second, width, height)
      if (!pixelMap) {
        result.success(null)
        return
      }

      const bytes = await this.pixelMapToBytes(pixelMap, format, quality)
      result.success(bytes)
    } catch (error) {
      Log.e(TAG, error.toString())
      result.error('GET_FRAME_BYTES_ERROR', error.toString(), null)
    }
  }

  private getFileName(path:string):string{
    const l = path.split("/")
    const name = l[l.length - 1]
    return name.split(".")[0]
  }

  private async handleGetFramesToFiles(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const seconds: number[] = call.argument("seconds") as number[]
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean
      const cacheDir: string = call.argument("cacheDir") as string
      const videoName = this.getFileName(filePath)
      Log.i(TAG, `handleGetFramesToFiles cacheDir=${cacheDir}  seconds=${seconds}`)

      const filePaths: string[] = []
      for (let i = 0; i < seconds.length; i++) {
        const second = seconds[i]
        const pixelMap = await this.extractFrame(filePath, second, width, height)
        if (pixelMap) {
          const fileName = `${videoName}_frame_${second}.${format}`
          const fullPath =  `${cacheDir}/${fileName}`
          const success = await this.savePixelMapToFile(pixelMap, fullPath, format, quality)
          if (success) {
            filePaths.push(fullPath)
          } else {
            filePaths.push('')
          }
        } else {
          filePaths.push('')
        }
      }
      result.success(filePaths)
    } catch (error) {
      Log.e(TAG, `handleGetFramesToFiles ${error.toString()}`)
      result.error('GET_FRAMES_TO_FILES_ERROR', error.toString(), null)
    }
  }

  private async handleGetFrameToFile(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string = call.argument("filePath") as string
      const second: number = call.argument("second") as number
      const width: number = call.argument("width") as number
      const height: number = call.argument("height") as number
      const format: string = call.argument("format") as string
      const quality: number = call.argument("quality") as number
      const exactTime: boolean = call.argument("exactTime") as boolean
      const cacheDir: string = call.argument("cacheDir") as string
      const videoName: string = this.getFileName(filePath)
      const pixelMap = await this.extractFrame(filePath, second, width, height)
      if (!pixelMap) {
        result.success(null)
        return
      }

      const fileName = `${videoName}_frame_${second}.${format}`
      const fullPath = `${cacheDir}/${fileName}`
      const success = await this.savePixelMapToFile(pixelMap, fullPath, format, quality)
      
      if (success) {
        result.success(fullPath)
      } else {
        result.success(null)
      }
    } catch (error) {
      Log.e(TAG, error.toString())
      result.error('GET_FRAME_TO_FILE_ERROR', error.toString(), null)
    }
  }

  private async extractFrame(
    filePath: string, 
    second: number, 
    width?: number, 
    height?: number,
  ): Promise<image.PixelMap | null> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY)
      const fd = file.fd

      const avImageGenerator = await media.createAVImageGenerator()
      avImageGenerator.fdSrc = { fd: fd}

      const queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_CLOSEST
      const pixelMap = await avImageGenerator.fetchFrameByTime(second * 1000000, queryOption, {
        width: width,
        height: height,
      })

      await avImageGenerator.release()
      fs.close(file)

      return pixelMap
    } catch (error) {
      Log.e(TAG, `extractFrame failed: file=${filePath}, time=${second}s, width=${width}, height=${height} error=${error.code} ${error.message}`)
      return null
    }
  }

  private async pixelMapToBytes(
    pixelMap: image.PixelMap, 
    format: string = 'jpeg', 
    quality: number = 85
  ): Promise<Uint8Array | null> {
    try {
      const imagePacker = await image.createImagePacker()
      const packOptions: image.PackingOption = {
        format: format === 'png' ? 'image/png' : 'image/jpeg',
        quality: quality,
      }
      
      const buffer = await imagePacker.packToData(pixelMap, packOptions)
      return new Uint8Array(buffer)
    } catch (error) {
      Log.e(TAG, `pixelMapToBytes: ${error.toString()}`)
      return null
    }
  }

  private async savePixelMapToFile(
    pixelMap: image.PixelMap, 
    filePath: string, 
    format: string = 'jpeg',
    quality: number = 85
  ): Promise<boolean> {
    try {
      Log.i(TAG, `filePath=${filePath} format=${format} quality=${quality} pixelMap=${pixelMap}`)
      const bytes = await this.pixelMapToBytes(pixelMap, format, quality)
      if (!bytes) {
        return false
      }

      const file =  await fs.open(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
      const writeSize = await fs.write(file.fd, bytes.buffer)
      await fs.close(file)

      return writeSize === bytes.length
    } catch (error) {
      Log.e(TAG, `savePixelMapToFile ${error.toString()}`)
      return false
    }
  }
}