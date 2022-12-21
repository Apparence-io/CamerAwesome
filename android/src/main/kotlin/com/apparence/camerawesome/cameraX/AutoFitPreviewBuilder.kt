package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Matrix
import android.hardware.display.DisplayManager
import android.util.Size
import android.view.Display
import android.view.Surface
import android.view.TextureView
import android.view.View
import androidx.camera.core.Preview
import androidx.camera.core.impl.PreviewConfig
import java.lang.ref.WeakReference
import java.util.*
import kotlin.math.roundToInt

/**
 * Builder for [Preview] that takes in a [WeakReference] of the view finder and
 * [PreviewConfig], then instantiates a [Preview] which automatically
 * resizes and rotates reacting to config changes.
 *
 * credits to yevhenRoman
 * https://gist.github.com/yevhenRoman/90681822adef43350844464be95d23f1
 */
@SuppressLint("RestrictedApi")
class AutoFitPreviewBuilder private constructor(
    config: PreviewConfig,
    viewFinderRef: WeakReference<TextureView>
) {
    /** Public instance of preview use-case which can be used by consumers of this adapter */
    val useCase: Preview

    /** Internal variable used to keep track of the use-case's output rotation */
    private var bufferRotation: Int = 0

    /** Internal variable used to keep track of the view's rotation */
    private var viewFinderRotation: Int? = null

    /** Internal variable used to keep track of the use-case's output dimension */
    private var bufferDimens: Size = Size(0, 0)

    /** Internal variable used to keep track of the view's dimension */
    private var viewFinderDimens: Size = Size(0, 0)

    /** Internal variable used to keep track of the view's display */
    private var viewFinderDisplay: Int = -1

    private lateinit var displayManager: DisplayManager

    /** We need a display listener for 180 degree device orientation changes */
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) {
            val viewFinder = viewFinderRef.get() ?: return
            if (displayId != viewFinderDisplay) {
                val display = displayManager.getDisplay(displayId)
                val rotation = getDisplaySurfaceRotation(display)
                updateTransform(viewFinder, rotation, bufferDimens, viewFinderDimens)
            }
        }
    }

    init {
        // Make sure that the view finder reference is valid
        val viewFinder = viewFinderRef.get() ?: throw IllegalArgumentException(
            "Invalid reference to view finder used"
        )

        // Initialize the display and rotation from texture view information
        viewFinderDisplay = viewFinder.display.displayId
        viewFinderRotation = getDisplaySurfaceRotation(viewFinder.display) ?: 0

        // Initialize public use-case with the given config
        useCase = Preview.Builder
            .fromConfig(config)
            .build();

        // Every time the view finder is updated, recompute layout
//        useCase.onPreviewOutputUpdateListener = Preview.OnPreviewOutputUpdateListener {
//            val viewFinder =
//                    viewFinderRef.get() ?: return@OnPreviewOutputUpdateListener
//
//            // To update the SurfaceTexture, we have to remove it and re-add it
//            val parent = viewFinder.parent as ViewGroup
//            parent.removeView(viewFinder)
//            parent.addView(viewFinder, 0)
//
//            viewFinder.surfaceTexture = it.surfaceTexture
//            bufferRotation = it.rotationDegrees
//            val rotation = getDisplaySurfaceRotation(viewFinder.display)
//            updateTransform(viewFinder, rotation, it.textureSize, viewFinderDimens)
//        }

        // Every time the provided texture view changes, recompute layout
        viewFinder.addOnLayoutChangeListener { view, left, top, right, bottom, _, _, _, _ ->
            val viewFinder = view as TextureView
            val newViewFinderDimens = Size(right - left, bottom - top)
            val rotation = getDisplaySurfaceRotation(viewFinder.display)
            updateTransform(viewFinder, rotation, bufferDimens, newViewFinderDimens)
        }

        // Every time the orientation of device changes, recompute layout
        displayManager = viewFinder.context
            .getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayManager.registerDisplayListener(displayListener, null)

        // Remove the display listeners when the view is detached to avoid
        // holding a reference to the View outside of a Fragment.
        // NOTE: Even though using a weak reference should take care of this,
        // we still try to avoid unnecessary calls to the listener this way.
        viewFinder.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(view: View) {}
            override fun onViewDetachedFromWindow(view: View) {
                displayManager.unregisterDisplayListener(displayListener)
            }
        })
    }

    /** Helper function that fits a camera preview into the given [TextureView] */
    private fun updateTransform(
        textureView: TextureView?, rotation: Int?, newBufferDimens: Size,
        newViewFinderDimens: Size
    ) {
        // This should happen anyway, but now the linter knows
        val textureView = textureView ?: return

        if (rotation == viewFinderRotation &&
            Objects.equals(newBufferDimens, bufferDimens) &&
            Objects.equals(newViewFinderDimens, viewFinderDimens)
        ) {
            // Nothing has changed, no need to transform output again
            return
        }

        if (rotation == null) {
            // Invalid rotation - wait for valid inputs before setting matrix
            return
        } else {
            // Update internal field with new inputs
            viewFinderRotation = rotation
        }

        if (newBufferDimens.width == 0 || newBufferDimens.height == 0) {
            // Invalid buffer dimens - wait for valid inputs before setting matrix
            return
        } else {
            // Update internal field with new inputs
            bufferDimens = newBufferDimens
        }

        if (newViewFinderDimens.width == 0 || newViewFinderDimens.height == 0) {
            // Invalid view finder dimens - wait for valid inputs before setting matrix
            return
        } else {
            // Update internal field with new inputs
            viewFinderDimens = newViewFinderDimens
        }

        val matrix = Matrix()

        // Compute the center of the view finder
        val centerX = viewFinderDimens.width / 2f
        val centerY = viewFinderDimens.height / 2f

        // Correct preview output to account for display rotation
        matrix.postRotate(-viewFinderRotation!!.toFloat(), centerX, centerY)

        // Buffers are rotated relative to the device's 'natural' orientation: swap width and height
        val bufferRatio = bufferDimens.height / bufferDimens.width.toFloat()

        val scaledWidth: Int
        val scaledHeight: Int
        // Match longest sides together -- i.e. apply center-crop transformation
        if (viewFinderDimens.width > viewFinderDimens.height) {
            scaledWidth = viewFinderDimens.width
            scaledHeight = (viewFinderDimens.width / bufferRatio).roundToInt()
        } else {
            scaledHeight = viewFinderDimens.height
            scaledWidth = Math.round(viewFinderDimens.height * bufferRatio)
        }

        // Compute the relative scale value
        val xScale = scaledWidth / viewFinderDimens.width.toFloat()
        val yScale = scaledHeight / viewFinderDimens.height.toFloat()

        // Scale input buffers to fill the view finder
        matrix.preScale(xScale, yScale, centerX, centerY)

        // Finally, apply transformations to our TextureView
        textureView.setTransform(matrix)
    }

    companion object {
        /** Helper function that gets the rotation of a [Display] in degrees */
        fun getDisplaySurfaceRotation(display: Display?) = when (display?.rotation) {
            Surface.ROTATION_0 -> 0
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> null
        }

        /**
         * Main entrypoint for users of this class: instantiates the adapter and returns an instance
         * of [Preview] which automatically adjusts in size and rotation to compensate for
         * config changes.
         */
        fun build(config: PreviewConfig, viewFinder: TextureView) =
            AutoFitPreviewBuilder(config, WeakReference(viewFinder)).useCase
    }
}