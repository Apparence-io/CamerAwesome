package com.apparence.camerawesome.buttons

import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Message
import android.os.Messenger
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media.VolumeProviderCompat


class PlayerService : Service() {
    private var mediaSession: MediaSessionCompat? = null
    private var messenger: Messenger? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        messenger =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) intent!!.extras!!.getParcelable(
                PhysicalButtonsHandler.BROADCAST_VOLUME_BUTTONS, Messenger::class.java
            )!!
            else intent!!.extras!!.getParcelable(PhysicalButtonsHandler.BROADCAST_VOLUME_BUTTONS)!!

        return super.onStartCommand(intent, flags, startId)
    }

    override fun onCreate() {
        super.onCreate()


        mediaSession = MediaSessionCompat(this, "PlayerService")
        mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder().setState(
                PlaybackStateCompat.STATE_PLAYING, 0, 0f
            ) // Simulate a player which plays something.
                .build()
        )

        val myVolumeProvider: VolumeProviderCompat = object : VolumeProviderCompat(
            VOLUME_CONTROL_RELATIVE,
            100,  /*max volume*/
            50  /*initial volume level*/
        ) {
            override fun onAdjustVolume(direction: Int) {
                /*
                -1 -- volume down
                1 -- volume up
                0 -- volume button released
                 */
                if (direction < 0) {
                    messenger?.send(Message.obtain().apply {
                        arg1 = PhysicalButtonsHandler.VOLUME_DOWN
                    })
                } else if (direction > 0) {
                    messenger?.send(Message.obtain().apply {
                        arg1 = PhysicalButtonsHandler.VOLUME_UP
                    })
                }
            }
        }
        mediaSession?.setPlaybackToRemote(myVolumeProvider)
        mediaSession?.isActive = true
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaSession?.release()
    }
}