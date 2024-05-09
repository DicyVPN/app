package com.dicyvpn.android

import android.util.Log
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import io.flutter.app.FlutterApplication
import java.io.StringReader
import java.lang.ref.WeakReference

class DicyVPN : FlutterApplication() {
    private var backend: GoBackend? = null
    private val tunnel: VPNTunnel = VPNTunnel()

    override fun onCreate() {
        super.onCreate()

        try {
            backend = GoBackend(applicationContext)

        } catch (e: Throwable) {
            Log.e(TAG, Log.getStackTraceString(e))
        }
    }

    companion object {
        private const val TAG = "DicyVPN/Application"
        private lateinit var weakSelf: WeakReference<DicyVPN>

        fun get(): DicyVPN {
            return weakSelf.get()!!
        }

        fun getTunnel() = get().tunnel

        fun setTunnelUp(config: String) {
            val instance = get()
            instance.backend?.setState(instance.tunnel, Tunnel.State.UP, Config.parse(StringReader(config).buffered()))
        }

        fun setTunnelDown() {
            val instance = get()
            instance.backend?.setState(instance.tunnel, Tunnel.State.DOWN, null)
        }
    }

    init {
        weakSelf = WeakReference(this)
    }
}