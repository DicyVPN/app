import UIKit
import Flutter

import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var wgMethodChannel = "wireguard_native.dicyvpn.com/method"
    private var wgEventChannel = "wireguard_native.dicyvpn.com/event"
    
    private static var vpnStatusSink: StatusSink?
    
    
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
                    result(true)
                    break
                case "start":
                    let config: String? = (call.arguments as? [String: String])?["config"]
                    if config != nil {
                        self.start(config: config!, result: result)
                    } else {
                        result(FlutterError(code: "missing_argument", message: "Missing argument 'config'", details: nil))
                    }
                    break
                case "stop":
                    self.stop(result: result)
                    break
                case "getStatus":
                    result(Tunnel.lastStatus.rawValue)
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
    
    private func start(config: String, result: @escaping FlutterResult) {
        Tunnel.start(config: config) { success in
            result(success)
        }
    }
    private func stop(result: @escaping FlutterResult) {
        Tunnel.stop() { succes in
            result(succes)
        }
    }
    
    
    class VPNStatusHandler: NSObject, FlutterStreamHandler {
        private var vpnConnectionObserver: NSObjectProtocol?
        
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            // Remove existing observer if any
            if let observer = vpnConnectionObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            
            vpnConnectionObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil
            ) { [weak self] notification in
                guard let self = self, AppDelegate.vpnStatusSink != nil else {
                    // Check if self or connection is nil and return early if that's the case
                    return
                }
                
                let nevpnconn = notification.object as! NEVPNConnection
                let status = nevpnconn.status
                
                Tunnel.onStatusChange(nevpnStatus: status)
            }
            
            vpnStatusSink = StatusSink(sink: events)
            
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                var status = managers?.first?.connection.status
                if (status != nil) {
                    events(Tunnel.onStatusChange(nevpnStatus: status!))
                }
            }
            
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            vpnStatusSink = nil
            return nil
        }
    }
    
    class Tunnel {
        static var lastStatus: Status = Status.disconnected
        
        static func start(config: String, completion: @escaping (Bool) -> Void) {
            NETunnelProviderManager.loadAllFromPreferences{ tunnelManagersInSettings, error in
                if let error = error {
                    NSLog("Error (loadAllFromPreferences): \(error)")
                    completion(false)
                    return
                }
                let preExistingTunnelManager = tunnelManagersInSettings?.first
                let tunnelManager = preExistingTunnelManager ?? NETunnelProviderManager()
                
                let protocolConfiguration = NETunnelProviderProtocol()
                
                // TODO: might not be needed // protocolConfiguration.providerBundleIdentifier = ""
                protocolConfiguration.providerConfiguration = [
                    "config": config
                ]
                
                tunnelManager.protocolConfiguration = protocolConfiguration
                tunnelManager.isEnabled = true
                
                tunnelManager.saveToPreferences { error in
                    if let error = error {
                        NSLog("Error (saveToPreferences): \(error)")
                        completion(false)
                    } else {
                        tunnelManager.loadFromPreferences { error in
                            if let error = error {
                                NSLog("Error (loadFromPreferences): \(error)")
                                completion(false)
                            } else {
                                NSLog("Starting the tunnel")
                                if let session = tunnelManager.connection as? NETunnelProviderSession {
                                    do {
                                        try session.startTunnel(options: nil)
                                        completion(true)
                                    } catch {
                                        NSLog("Error (startTunnel): \(error)")
                                        completion(false)
                                    }
                                } else {
                                    NSLog("tunnelManager.connection is invalid")
                                    completion(false)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        static func stop(completion: @escaping (Bool?) -> Void) {
            NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
                if let error = error {
                    NSLog("Error (loadAllFromPreferences): \(error)")
                    completion(false)
                    return
                }
                
                if let tunnelManager = tunnelManagersInSettings?.first {
                    guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                        NSLog("tunnelManager.connection is invalid")
                        completion(false)
                        return
                    }
                    switch session.status {
                    case .connected, .connecting, .reasserting:
                        NSLog("Stopping the tunnel")
                        session.stopTunnel()
                        completion(true)
                    default:
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }
        
        static func onStatusChange(nevpnStatus: NEVPNStatus) {
            let newStatus: Status = switch nevpnStatus {
            case NEVPNStatus.connected:
                Status.connected
            case NEVPNStatus.connecting:
                Status.connecting
            case NEVPNStatus.disconnected:
                Status.disconnected
            case NEVPNStatus.disconnecting:
                Status.disconnecting
            case NEVPNStatus.invalid, NEVPNStatus.reasserting:
                lastStatus
            @unknown default:
                lastStatus
            }
            
            if (lastStatus != newStatus) {
                lastStatus = newStatus
                AppDelegate.vpnStatusSink?.success(event: lastStatus)
            }
        }
    }
}
