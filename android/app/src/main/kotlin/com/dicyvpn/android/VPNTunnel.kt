package com.dicyvpn.android

import com.wireguard.android.backend.Tunnel

class VPNTunnel : Tunnel {
    private var statusSink: StatusSink? = null
    private var lastState: Tunnel.State = Tunnel.State.DOWN
    private val waitForStoppedCallbacks: MutableList<() -> Unit> = mutableListOf()

    override fun getName(): String {
        return "DicyVPN"
    }

    override fun onStateChange(newState: Tunnel.State) {
        lastState = newState

        if (newState == Tunnel.State.UP) {
            statusSink?.success(Status.CONNECTED)
        } else if (newState == Tunnel.State.DOWN) {
            statusSink?.success(Status.DISCONNECTED)

            waitForStoppedCallbacks.removeAll {
                it()
                true
            }
        }
    }

    fun waitForStopped(callback: () -> Unit) {
        if (lastState == Tunnel.State.DOWN) {
            callback()
            return
        }

        waitForStoppedCallbacks += callback
    }

    fun setStatusSink(statusSink: StatusSink?) {
        this.statusSink = statusSink;
    }
}
