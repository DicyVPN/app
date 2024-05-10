package com.dicyvpn.android

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch


class MainActivity : FlutterActivity() {
    private val tag = "DicyVPN/Activity"
    private val wgMethodChannel = "wireguard_native.dicyvpn.com/method"
    private val wgEventChannel = "wireguard_native.dicyvpn.com/event"
    private var vpnStatusSink: StatusSink? = null

    private val permissionsRequestCode = 10777
    private var requestPermissionResult: MethodChannel.Result? = null
    private val coroutineScope = CoroutineScope(Job() + Dispatchers.Main.immediate)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            wgMethodChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestPermission(result)
                "start" -> {
                    val config = call.argument<String>("config");
                    if (config != null) {
                        start(config, result)
                    } else {
                        result.error("missing_argument", "Missing argument 'config'", null)
                    }
                }

                "stop" -> stop(result)
                "getStatus" -> result.success(DicyVPN.getTunnel().getStatus().value)
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, wgEventChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink) {
                    vpnStatusSink = StatusSink(events)
                    DicyVPN.getTunnel().setStatusSink(vpnStatusSink, coroutineScope)
                }

                override fun onCancel(arguments: Any?) {
                    vpnStatusSink = null
                    DicyVPN.getTunnel().setStatusSink(null, coroutineScope)
                }
            }
        )
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(DicyVPN.get())
        if (intent == null) {
            result.success(null)
            Log.i(tag, "VPN permission granted")
        } else {
            requestPermissionResult = result
            startActivityForResult(intent, permissionsRequestCode)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != permissionsRequestCode) {
            return
        }
        if (resultCode == Activity.RESULT_OK) {
            requestPermissionResult?.success(null) // delayed return
            Log.i(tag, "VPN permission granted, starting tunnel")
        } else {
            requestPermissionResult?.error("permission_denied", "Permission has been denied", null)
            Log.i(tag, "VPN permission denied")
        }
        requestPermissionResult = null // cleanup
    }

    private fun start(config: String, result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            DicyVPN.setTunnelUp(config)
            result.success(null)
        }
    }

    private fun stop(result: MethodChannel.Result) {
        DicyVPN.setTunnelDown()
        result.success(null)
    }

    /*
    private fun connect(wgQuickConfig: String, result: MethodChannel.Result?) {
        coroutineScope.launch(Dispatchers.IO) {

            val intent = VpnService.prepare(DicyVPN.get())
            if (intent != null) { // permission needed
                startActivityForResult(intent, permissionsRequestCode)
            } else {


                try {
                    if (!havePermission) {
                        checkPermission()
                        throw Exception("Permissions are not given")
                    }
                    updateStage("prepare")
                    val inputStream = ByteArrayInputStream(wgQuickConfig.toByteArray())
                    config = com.wireguard.config.Config.parse(inputStream)
                    updateStage("connecting")
                    futureBackend.await().setState(
                        tunnel(tunnelName) { state ->
                            scope.launch(Dispatchers.Main) {
                                Log.i(tag, "onStateChange - $state")
                                updateStageFromState(state)
                            }
                        }, Tunnel.State.UP, config
                    )
                    Log.i(tag, "Connect - success!")
                    flutterSuccess(result, "")
                } catch (e: BackendException) {
                    Log.e(tag, "Connect - BackendException - ERROR - ${e.reason}", e)
                    flutterError(result, e.reason.toString())
                } catch (e: Throwable) {
                    Log.e(tag, "Connect - Can't connect to tunnel: $e", e)
                    flutterError(result, e.message.toString())
                }
            }
        }

        override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
            this.activity = activityPluginBinding.activity as FlutterActivity
        }

        override fun onDetachedFromActivityForConfigChanges() {
            this.activity = null
        }

        override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
            this.activity = activityPluginBinding.activity as FlutterActivity
        }

        override fun onDetachedFromActivity() {
            this.activity = null
        }

        override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
            channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
            events = EventChannel(flutterPluginBinding.binaryMessenger, METHOD_EVENT_NAME)
            context = flutterPluginBinding.applicationContext

            scope.launch(Dispatchers.IO) {
                try {
                    backend = createBackend()
                    futureBackend.complete(backend!!)
                } catch (e: Throwable) {
                    Log.e(tag, Log.getStackTraceString(e))
                }
            }

            channel.setMethodCallHandler(this)
            events.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink?) {
                    isVpnChecked = false
                    vpnStageSink = events
                }

                override fun onCancel(arguments: Any?) {
                    isVpnChecked = false
                    vpnStageSink = null
                }
            })

        }

        private fun createBackend(): Backend {
            if (backend == null) {
                backend = GoBackend(context)
            }
            return backend as Backend
        }

        private fun flutterSuccess(result: MethodChannel.Result, o: Any) {
            scope.launch(Dispatchers.Main) {
                result.success(o)
            }
        }

        private fun flutterError(result: MethodChannel.Result, error: String) {
            scope.launch(Dispatchers.Main) {
                result.error(error, null, null)
            }
        }

        private fun flutterNotImplemented(result: MethodChannel.Result) {
            scope.launch(Dispatchers.Main) {
                result.notImplemented()
            }
        }

        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

            when (call.method) {
                "initialize" -> setupTunnel(call.argument<String>("localizedDescription").toString(), result)
                "start" -> {
                    connect(call.argument<String>("wgQuickConfig").toString(), result)

                    if (!isVpnChecked) {
                        if (isVpnActive()) {
                            state = "connected"
                            isVpnChecked = true
                            println("VPN is active")
                        } else {
                            state = "disconnected"
                            isVpnChecked = true
                            println("VPN is not active")
                        }
                    }
                }

                "stop" -> {
                    disconnect(result)
                }

                "stage" -> {
                    result.success(getStatus())
                }

                "checkPermission" -> {
                    checkPermission()
                    result.success(null)
                }

                else -> flutterNotImplemented(result)
            }
        }

        private fun isVpnActive(): Boolean {
            try {
                val connectivityManager =
                    context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val activeNetwork = connectivityManager.activeNetwork
                    val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
                    return networkCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                } else {
                    return false
                }
            } catch (e: Exception) {
                Log.e(tag, "isVpnActive - ERROR - ${e.message}")
                return false
            }
        }

        private fun updateStage(stage: String?) {
            scope.launch(Dispatchers.Main) {
                val updatedStage = stage ?: "no_connection"
                state = updatedStage
                vpnStageSink?.success(updatedStage.lowercase(Locale.ROOT))
            }
        }

        private fun updateStageFromState(state: Tunnel.State) {
            scope.launch(Dispatchers.Main) {
                when (state) {
                    Tunnel.State.UP -> updateStage("connected")
                    Tunnel.State.DOWN -> updateStage("disconnected")
                    else -> updateStage("wait_connection")
                }
            }
        }

        private fun disconnect(result: MethodChannel.Result) {
            scope.launch(Dispatchers.IO) {
                try {
                    if (futureBackend.await().runningTunnelNames.isEmpty()) {
                        updateStage("disconnected")
                        throw Exception("Tunnel is not running")
                    }
                    updateStage("disconnecting")
                    futureBackend.await().setState(
                        tunnel(tunnelName) { state ->
                            scope.launch(Dispatchers.Main) {
                                Log.i(tag, "onStateChange - $state")
                                updateStageFromState(state)
                            }
                        }, Tunnel.State.DOWN, config
                    )
                    Log.i(tag, "Disconnect - success!")
                    flutterSuccess(result, "")
                } catch (e: BackendException) {
                    Log.e(tag, "Disconnect - BackendException - ERROR - ${e.reason}", e)
                    flutterError(result, e.reason.toString())
                } catch (e: Throwable) {
                    Log.e(tag, "Disconnect - Can't disconnect from tunnel: ${e.message}")
                    flutterError(result, e.message.toString())
                }
            }
        }


        private fun setupTunnel(localizedDescription: String, result: MethodChannel.Result) {
            scope.launch(Dispatchers.IO) {
                if (Tunnel.isNameInvalid(localizedDescription)) {
                    flutterError(result, "Invalid Name")
                    return@launch
                }
                tunnelName = localizedDescription
                checkPermission()
                result.success(null)
            }
        }

        private fun checkPermission() {
            val intent = GoBackend.VpnService.prepare(this.activity)
            if (intent != null) {
                havePermission = false
                this.activity?.startActivityForResult(intent, permissionsRequestCode)
            } else {
                havePermission = true
            }
        }

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
            channel.setMethodCallHandler(null)
            events.setStreamHandler(null)
            isVpnChecked = false
        }

        private fun tunnel(name: String, callback: StateChangeCallback? = null): WireGuardTunnel {
            if (tunnel == null) {
                tunnel = WireGuardTunnel(name, callback)
            }
            return tunnel as WireGuardTunnel
        }
    }

    typealias StateChangeCallback = (Tunnel.State) -> Unit

    class WireGuardTunnel(
        private val name: String, private val onStateChanged: StateChangeCallback? = null
    ) : Tunnel {

        override fun getName() = name

        override fun onStateChange(newState: Tunnel.State) {
            onStateChanged?.invoke(newState)
        }

    }*/
}
