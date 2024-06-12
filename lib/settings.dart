import 'package:dicyvpn/ui/components/custom_app_bar.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _enableCustomDNS = false;
  DNSType _selectedDNSType = DNSType.cloudflare;
  late final Map<DNSType, List<String>> _dnsByType;
  final editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dnsByType = {
      DNSType.cloudflare: ['1.1.1.1', '1.0.0.1'],
      DNSType.google: ['8.8.8.8', '8.8.4.4'],
      DNSType.custom: ['192.168.1.1', '10.0.0.1'],
    };
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 24;
    var currentDNSList = _dnsByType[_selectedDNSType]!;

    return Scaffold(
      appBar: CustomAppBar.getAppBar(canGoBack: true),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SwitchListTile.adaptive(
                      title: Text(tr('settingsUseCustomDNSServers')),
                      value: _enableCustomDNS,
                      onChanged: (value) {
                        setState(() {
                          _enableCustomDNS = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: padding),
                    child: Text(
                      tr('settingsCustomDNSDescription'),
                      style: const TextStyle(color: CustomColors.gray100),
                    ),
                  ),
                  Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(padding, padding + 8, padding, padding),
                            child: CupertinoSlidingSegmentedControl(
                              children: {
                                DNSType.cloudflare: const Text('Cloudflare'),
                                DNSType.google: const Text('Google'),
                                DNSType.custom: Text(tr('settingsDNSCustom')),
                              },
                              onValueChanged: (type) {
                                if (type != null) {
                                  setState(() {
                                    _selectedDNSType = type;
                                  });
                                }
                              },
                              groupValue: _selectedDNSType,
                              thumbColor: CustomColors.gray300,
                            ),
                          ),
                          if (_selectedDNSType == DNSType.custom)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(padding, 0, padding, 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: editingController,
                                  decoration: InputDecoration(
                                    hintText: '8.8.8.8',
                                    hintStyle: const TextStyle(fontFamily: 'monospace', color: CustomColors.gray300),
                                    border: InputBorder.none,
                                    filled: true,
                                    suffixIcon: IconButton(
                                      onPressed: _tryAddingDNS,
                                      icon: const Icon(Icons.add),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (currentDNSList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: padding),
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                child: Text(
                                  tr('settingsNoCustomDNS'),
                                  style: const TextStyle(color: CustomColors.gray100, fontSize: 16),
                                ),
                              ),
                            )
                          else
                            for (int i = 0; i < currentDNSList.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 4),
                                child: Container(
                                  width: double.infinity,
                                  height: 40,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: CustomColors.gray800,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(currentDNSList[i],
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                                        ),
                                      ),
                                      if (_selectedDNSType == DNSType.custom)
                                        Material(
                                          color: CustomColors.gray400,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                currentDNSList.removeAt(i);
                                              });
                                            },
                                            child: const SizedBox(
                                              height: double.infinity,
                                              width: 48,
                                              child: Icon(
                                                Icons.delete,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                      if (!_enableCustomDNS)
                        Positioned(
                          left: 0,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            // ignore: deprecated_member_use
                            color: Theme.of(context).colorScheme.background.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tryAddingDNS() {
    setState(() {
      String ipAddress = editingController.text.trim();
      try {
        Uri.parseIPv4Address(ipAddress);
      } catch (_) {
        try {
          Uri.parseIPv6Address(ipAddress);
        } catch (_) {
          // not an IPv4 or IPv6 address
          ScaffoldMessenger.of(navigationKey.currentContext!).showSnackBar(SnackBar(
            content: Text(tr('settingsInvalidIPAddress', namedArgs: {'address': ipAddress})),
          ));
          return;
        }
      }
      // valid IPv4 or IPv6 address
      _dnsByType[_selectedDNSType]?.add(ipAddress);
      editingController.clear();
    });
  }
}

enum DNSType { cloudflare, google, custom }
