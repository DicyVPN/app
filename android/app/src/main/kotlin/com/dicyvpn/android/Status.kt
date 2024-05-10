package com.dicyvpn.android

enum class Status(val value: String) {
    CONNECTING("connecting"),
    CONNECTED("connected"),
    DISCONNECTED("disconnected"),
    DISCONNECTING("disconnecting")
}
