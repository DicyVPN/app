//
//  StatusSink.swift
//  Runner
//
//  Created by user258751 on 5/17/24.
//

import Flutter

class StatusSink {
    private var sink: FlutterEventSink
    
    init(sink: @escaping FlutterEventSink) {
        self.sink = sink
    }
    
    func success(event: Status) {
        sink(event.rawValue)
    }
    
    func error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        sink(FlutterError(code: errorCode, message: errorMessage, details: errorDetails))
    }
    
    func endOfStream() {
        sink(FlutterEndOfEventStream)
    }
}
