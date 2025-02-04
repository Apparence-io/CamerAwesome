package com.apparence.camerawesome.cameraX

import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import kotlin.math.min

class AnalysisImageConverter : AnalysisImageUtils {
    override fun nv21toJpeg(
        nv21Image: AnalysisImageWrapper,
        jpegQuality: Long,
        callback: (Result<AnalysisImageWrapper>) -> Unit
    ) {
        val out = ByteArrayOutputStream()
        val yuv = YuvImage(
            nv21Image.bytes, ImageFormat.NV21,
            nv21Image.width.toInt(), nv21Image.height.toInt(),
            // TODO strides might not always be null
            null
        )
        val success = yuv.compressToJpeg(
            Rect(
                nv21Image.cropRect?.left?.toInt() ?: 0, nv21Image.cropRect?.top?.toInt() ?: 0,
                nv21Image.cropRect?.width?.toInt() ?: nv21Image.width.toInt(),
                nv21Image.cropRect?.height?.toInt() ?: nv21Image.height.toInt(),
            ),
            jpegQuality.toInt(), out
        )
        if (!success) {
            callback(
                Result.failure(
                    Exception(
                        "YuvImage failed to encode jpeg."
                    )
                )
            )
        }
        callback(
            Result.success(
                AnalysisImageWrapper(
                    bytes = out.toByteArray(),
                    width = nv21Image.width,
                    height = nv21Image.height,
                    cropRect = nv21Image.cropRect,
                    format = AnalysisImageFormat.JPEG,
                    planes = null,
                    rotation = nv21Image.rotation
                )
            )
        )
    }

    override fun yuv420toJpeg(
        yuvImage: AnalysisImageWrapper,
        jpegQuality: Long,
        callback: (Result<AnalysisImageWrapper>) -> Unit
    ) {
        yuv420toNv21(yuvImage) { result ->
            result.onSuccess {
                nv21toJpeg(it, jpegQuality, callback)
            }
            result.onFailure {
                callback(Result.failure(it))
            }
        }

        // Below code throws the following:
        // java.lang.IllegalArgumentException: only support ImageFormat.NV21 and ImageFormat.YUY2 for now

//        val allPlanes = ByteArrayOutputStream()
//        yuvImage.planes?.forEach { plane ->
//            plane?.let {
//                allPlanes.write(it.bytes)
//            }
//        }
//
//        val out = ByteArrayOutputStream()
//        val yuv = YuvImage(
//            allPlanes.toByteArray(), ImageFormat.YUV_420_888,
//            yuvImage.width.toInt(), yuvImage.height.toInt(),
//            // TODO strides might not always be null
//            yuvImage.planes?.map { it!!.bytesPerRow.toInt() }?.toIntArray()
//        )
//        val success = yuv.compressToJpeg(
//            Rect(
//                yuvImage.cropRect?.left?.toInt() ?: 0, yuvImage.cropRect?.top?.toInt() ?: 0,
//                yuvImage.cropRect?.width?.toInt() ?: yuvImage.width.toInt(),
//                yuvImage.cropRect?.height?.toInt() ?: yuvImage.height.toInt(),
//            ),
//            jpegQuality.toInt(), out
//        )
//        if (!success) {
//            callback(
//                Result.failure<AnalysisImageWrapper>(
//                    Exception(
//                        "YuvImage failed to encode jpeg."
//                    )
//                )
//            )
//        }
//        callback(
//            Result.success(
//                AnalysisImageWrapper(
//                    bytes = out.toByteArray(),
//                    width = yuvImage.width,
//                    height = yuvImage.height,
//                    cropRect = yuvImage.cropRect,
//                    format = AnalysisImageFormat.JPEG,
//                    planes = null
//                )
//            )
//        )
    }

    override fun yuv420toNv21(
        yuvImage: AnalysisImageWrapper,
        callback: (Result<AnalysisImageWrapper>) -> Unit
    ) {
        val yPlane = yuvImage.planes!![0]!!
        val uPlane = yuvImage.planes[1]!!
        val vPlane = yuvImage.planes[2]!!

        val yBuffer = ByteBuffer.wrap(yPlane.bytes)
        val uBuffer = ByteBuffer.wrap(uPlane.bytes)
        val vBuffer = ByteBuffer.wrap(vPlane.bytes)
        yBuffer.rewind()
        uBuffer.rewind()
        vBuffer.rewind()

        val ySize = yBuffer.remaining()

        var position = 0

        val nv21 = ByteArray(ySize + yuvImage.width.toInt() * yuvImage.height.toInt() / 2)
        // Add the full y buffer to the array. If rowStride > 1, some padding may be skipped.

        // Add the full y buffer to the array. If rowStride > 1, some padding may be skipped.
        for (row in 0 until yuvImage.height) {
            yBuffer[nv21, position, yuvImage.width.toInt()]
            position += yuvImage.width.toInt()
            yBuffer.position(
                min(ySize, yBuffer.position() - yuvImage.width.toInt() + yPlane.bytesPerRow.toInt())
            )
        }

        val chromaHeight: Int = yuvImage.height.toInt() / 2
        val chromaWidth: Int = yuvImage.width.toInt() / 2
        val vRowStride = vPlane.bytesPerRow.toInt()
        val uRowStride = uPlane.bytesPerRow.toInt()
        val vPixelStride = vPlane.bytesPerPixel!!.toInt()
        val uPixelStride = uPlane.bytesPerPixel!!.toInt()

        // Interleave the u and v frames, filling up the rest of the buffer. Use two line buffers to
        // perform faster bulk gets from the byte buffers.

        // Interleave the u and v frames, filling up the rest of the buffer. Use two line buffers to
        // perform faster bulk gets from the byte buffers.
        val vLineBuffer = ByteArray(vRowStride)
        val uLineBuffer = ByteArray(uRowStride)
        for (row in 0 until chromaHeight) {
            vBuffer[vLineBuffer, 0, min(vRowStride, vBuffer.remaining())]
            uBuffer[uLineBuffer, 0, Math.min(uRowStride, uBuffer.remaining())]
            var vLineBufferPosition = 0
            var uLineBufferPosition = 0
            for (col in 0 until chromaWidth) {
                nv21[position++] = vLineBuffer[vLineBufferPosition]
                nv21[position++] = uLineBuffer[uLineBufferPosition]
                vLineBufferPosition += vPixelStride
                uLineBufferPosition += uPixelStride
            }
        }

        callback(
            Result.success(
                AnalysisImageWrapper(
                    bytes = nv21,
                    width = yuvImage.width,
                    height = yuvImage.height,
                    cropRect = yuvImage.cropRect,
                    format = AnalysisImageFormat.NV21,
                    planes = null,
                    rotation = yuvImage.rotation
                )
            )
        )
    }

    override fun bgra8888toJpeg(
        bgra8888image: AnalysisImageWrapper,
        jpegQuality: Long,
        callback: (Result<AnalysisImageWrapper>) -> Unit
    ) {
        callback(Result.failure(Exception("BGRA 8888 conversion not implemented on Android")))
    }
}