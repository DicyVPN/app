import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var wgMethodChannel = "wireguard_native.dicyvpn.com/method"
    private var wgEventChannel = "wireguard_native.dicyvpn.com/event"
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        FlutterMethodChannel(name: wgMethodChannel, binaryMessenger: controller.binaryMessenger)
            .setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                switch call.method {
                case "requestPermission":
                    //self.requestPermission(result)
                    break
                case "start":
                    let config: String? = (call.arguments as? [String: String])?["config"]
                    if config != nil {
                        //self.start(config, result)
                    } else {
                        result(FlutterError(code: "missing_argument", message: "Missing argument 'config'", details: nil))
                    }
                    break
                case "stop":
                    //self.stop(result)
                    break
                case "getStatus":
                    result("disconnected")
                    //result(DicyVPN.getTunnel().getStatus().value)
                    break
                default:
                    result(FlutterError(code: "not_implemented", message: "Method '" + call.method + "' is not implemented", details: nil))
                }
            })
        
        FlutterEventChannel(name: wgEventChannel, binaryMessenger: controller.binaryMessenger)
            .setStreamHandler(VPNStatusHandler())
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    
    class VPNStatusHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            return nil
        }
    }
}
