package com.dicyvpn.android

import io.flutter.plugin.common.EventChannel.EventSink

/**
 * Wrapper for a generic EventSink for type safety
 */
class StatusSink(private val sink: EventSink) {
    fun success(event: Status) {
        sink.success(event.name)
    }

    fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
        sink.error(errorCode, errorMessage, errorDetails)
    }

    fun endOfStream() {
        sink.endOfStream()
    }
}
