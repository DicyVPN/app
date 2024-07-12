import 'dart:convert';

import 'package:dicyvpn/ui/components/custom_app_bar.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Future<void> _readFromSettingsFuture;

  late bool _enableCustomDNS;
  late DNSType _selectedDnsType;
  late final Map<DNSType, List<String>> _dnsByType;

  final editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readFromSettingsFuture = _readFromSettings();
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 24;

    return Scaffold(
      appBar: CustomAppBar.getAppBar(canGoBack: true),
      body: SafeArea(
        child: FutureBuilder(
          future: _readFromSettingsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            var currentDnsList = _dnsByType[_selectedDnsType]!;
            return Align(
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
                              getStorage().write(key: 'vpn.useCustomDns', value: value.toString());
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
                                        _selectedDnsType = type;
                                        getStorage().write(key: 'vpn.customDnsType', value: type.name);
                                      });
                                    }
                                  },
                                  groupValue: _selectedDnsType,
                                  thumbColor: CustomColors.gray300,
                                ),
                              ),
                              if (_selectedDnsType == DNSType.custom)
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
                                        hintStyle:
                                            const TextStyle(fontFamily: 'monospace', color: CustomColors.gray300),
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
                              if (currentDnsList.isEmpty)
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
                                for (int i = 0; i < currentDnsList.length; i++)
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
                                              child: Text(currentDnsList[i],
                                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                                            ),
                                          ),
                                          if (_selectedDnsType == DNSType.custom)
                                            Material(
                                              color: CustomColors.gray400,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    currentDnsList.removeAt(i);
                                                    _saveDnsList(currentDnsList);
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
            );
          },
        ),
      ),
    );
  }

  /// Reads settings from storage and initializes the necessary variables.
  /// Returns a boolean indicating whether the operation was successful.
  Future<bool> _readFromSettings() async {
    var storage = getStorage();

    // Read the 'vpn.useCustomDns' setting from storage and assign it to '_enableCustomDNS'
    _enableCustomDNS = await storage.read(key: 'vpn.useCustomDns') == true.toString();

    // Read the 'vpn.customDnsType' setting from storage and assign it to 'dnsType'
    var dnsType = await storage.read(key: 'vpn.customDnsType');

    try {
      _selectedDnsType = DNSType.values.byName(dnsType!);
    } catch (_) {
      _selectedDnsType = DNSType.cloudflare;
    }

    // Read the 'vpn.dns' setting from storage and decode it as a JSON array
    var customDnsList = jsonDecode(await storage.read(key: 'vpn.dns') ?? '[]');

    List<String> validCustomDns = [];

    for (var dns in customDnsList) {
      if (_isIPValid(dns)) {
        validCustomDns.add(dns);
      }
    }

    // Assign the DNS values based on the selected DNS type
    _dnsByType = {
      DNSType.cloudflare: DNSType.cloudflare.dns,
      DNSType.google: DNSType.google.dns,
      DNSType.custom: validCustomDns,
    };

    // Return true to indicate that the operation was successful
    return true;
  }

  /// Tries to add a DNS address to the list of DNS addresses.
  /// If the provided IP address is valid, it is added to the list and saved.
  /// If the IP address is invalid, an error message is shown.
  void _tryAddingDNS() {
    setState(() {
      String ipAddress = editingController.text.trim();
      if (!_isIPValid(ipAddress)) {
        ScaffoldMessenger.of(navigationKey.currentContext!).showSnackBar(SnackBar(
          content: Text(tr('settingsInvalidIPAddress', namedArgs: {'address': ipAddress})),
        ));
        return;
      }
      // valid IPv4 or IPv6 address
      var dnsList = _dnsByType[_selectedDnsType]!;
      dnsList.add(ipAddress);
      _saveDnsList(dnsList);
      editingController.clear();
    });
  }

  /// Checks if the provided IP address is valid.
  /// Returns true if the address is a valid IPv4 or IPv6 address, false otherwise.
  bool _isIPValid(String address) {
    try {
      Uri.parseIPv4Address(address);
    } catch (_) {
      try {
        Uri.parseIPv6Address(address);
      } catch (_) {
        // not an IPv4 or IPv6 address
        return false;
      }
    }
    return true;
  }

  /// Saves the list of DNS addresses to persistent storage.
  void _saveDnsList(List<String> dnsList) {
    getStorage().write(key: 'vpn.dns', value: jsonEncode(dnsList));
  }
}
