/// Describes the status of the VPN connection.
/// [connecting] - The VPN is currently connecting.
/// [connected] - The VPN is connected.
/// [disconnecting] - The VPN is currently disconnecting.
/// [disconnected] - The VPN is disconnected.
enum Status {
  connecting,
  connected,
  disconnecting,
  disconnected;
}
