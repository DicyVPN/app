import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/vpn/status.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static const _backgroundColor = CustomColors.gray800;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: TextStyle(color: CustomColors.gray200),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: StatusCard(_backgroundColor),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: TextStyle(color: CustomColors.gray200),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ServerSelector(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final Color backgroundColor;

  const StatusCard(this.backgroundColor, {super.key});

  @override
  Widget build(BuildContext context) {
    var statusNotifier = VPN.get().status;
    var lastServerNotifier = VPN.get().lastServer;

    return ListenableBuilder(
      listenable: Listenable.merge([statusNotifier, lastServerNotifier]),
      builder: (context, child) {
        var status = statusNotifier.value;
        var lastServer = lastServerNotifier.value;

        var isVPNLoading = status == Status.connecting || status == Status.disconnecting;
        var connectButtonLabel = switch (status) {
          Status.connected => tr('labelDisconnect'),
          Status.connecting => tr('labelConnecting'),
          Status.disconnecting => tr('labelDisconnecting'),
          Status.disconnected => tr('labelConnect')
        };

        var notLoadingColor = status == Status.connected ? CustomColors.brightGreen : CustomColors.red300;

        if (lastServer != null) {
          return Column(
            children: [
              Row(
                children: [
                  StatusCircle(status, backgroundColor, isVPNLoading),
                ],
              ),
              Text(
                  'Server: ${lastServer.id}, ${lastServer.name}, ${lastServer.type}, ${lastServer.country}, ${lastServer.city}'),
              const SizedBox(height: 16),
              Button(
                  onPressed: () {
                    // navigationKey.currentState!.pushNamed('/logout');
                  },
                  theme: CustomButtonTheme.dark,
                  color: CustomButtonColor.green,
                  size: CustomButtonSize.normal,
                  child: const Text('Click me to set to NULL')),
            ],
          );
        }
        return Text(tr('chooseAServerFromTheList'), textAlign: TextAlign.center);
      },
    );
  }
}

class StatusCircle extends StatefulWidget {
  const StatusCircle(this.status, this.backgroundColor, this.isVPNLoading, {super.key});

  final Status status;
  final Color backgroundColor;
  final bool isVPNLoading;

  @override
  State<StatusCircle> createState() => _StatusCircleState();
}

class _StatusCircleState extends State<StatusCircle> with SingleTickerProviderStateMixin {
  final double _size = 18;
  final double _iconSize = 14;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration: const Duration(milliseconds: 500),
    )..forward();
    _controller.addStatusListener((status) {
      // repeat the animation after every second
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _controller.forward(from: 0.0);
          }
        });
      }
    });

    var pingCurve = const Cubic(0, 0, 0.2, 1);
    _scaleAnimation = Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(
      parent: _controller,
      curve: pingCurve,
    ));
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(
      parent: _controller,
      curve: pingCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var notLoadingColor = widget.status == Status.connected ? CustomColors.brightGreen : CustomColors.red300;
    var icon = widget.status == Status.connected ? Icons.check : Icons.close;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        if (widget.isVPNLoading) FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: notLoadingColor),
            ),
          ),
        ),
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: notLoadingColor),
        ),
        Icon(
          icon,
          size: _iconSize,
          color: widget.backgroundColor,
        )
      ],
    );
  }
}
