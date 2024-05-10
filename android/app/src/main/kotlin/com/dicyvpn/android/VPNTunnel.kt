package com.dicyvpn.android

import com.wireguard.android.backend.Tunnel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class VPNTunnel : Tunnel {
    private var coroutineScope: CoroutineScope? = null
    private var statusSink: StatusSink? = null
    private var lastState: Tunnel.State = Tunnel.State.DOWN

    override fun getName(): String {
        return "DicyVPN"
    }

    override fun onStateChange(newState: Tunnel.State) {
        lastState = newState

        coroutineScope?.launch(Dispatchers.Main) {
            if (newState == Tunnel.State.UP) {
                statusSink?.success(Status.CONNECTED)
            } else if (newState == Tunnel.State.DOWN) {
                statusSink?.success(Status.DISCONNECTED)
            }
        }
    }

    fun setStatusSink(statusSink: StatusSink?, coroutineScope: CoroutineScope) {
        this.coroutineScope = coroutineScope;
        this.statusSink = statusSink

        coroutineScope.launch(Dispatchers.Main) {
            statusSink?.success(getStatus()) // set initial value to last state
        }
    }

    fun getStatus(): Status {
        return when (lastState) {
            Tunnel.State.UP -> Status.CONNECTED
            else -> Status.DISCONNECTED
        }
    }
}
