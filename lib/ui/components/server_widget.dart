import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ServerWidget extends StatelessWidget {
  final Server server;

  final void Function(Server) onClick;

  const ServerWidget(this.server, this.onClick, {super.key});

  @override
  Widget build(BuildContext context) {
    var border = BorderRadius.circular(4);

    return Material(
      color: CustomColors.gray900,
      borderRadius: border,
      child: InkWell(
        borderRadius: border,
        onTap: () => onClick(server),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(server.city),
              const Spacer(),
              const SizedBox(width: 8),
              Container(
                height: 6,
                width: 6,
                decoration: BoxDecoration(color: _getLoadColor(), borderRadius: BorderRadius.circular(1)),
              ),
              const SizedBox(width: 8),
              Text(server.name, style: const TextStyle(fontFamily: 'monospace', color: CustomColors.gray300)),
              const SizedBox(width: 8),
              Flag(country: server.country),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLoadColor() {
    if (server.load > 0.85) return CustomColors.loadRed;
    if (server.load > 0.65) return CustomColors.loadOrange;
    if (server.load > 0.45) return CustomColors.loadYellow;
    return CustomColors.loadGreen;
  }
}

class Flag extends StatelessWidget {
  final String country;

  const Flag({required this.country, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SvgPicture.asset(
        'assets/flags/${country.toLowerCase()}.svg',
        width: 24,
        excludeFromSemantics: true,
      ),
    );
  }
}
