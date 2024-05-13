import 'dart:developer';

import 'package:country_picker/country_picker.dart';
import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'server_widget.dart';

class ServerSelector extends StatefulWidget {
  const ServerSelector(this.onServerClick, {super.key});

  final void Function(Server server) onServerClick;

  @override
  State<StatefulWidget> createState() {
    return _ServerSelectorState();
  }
}

class _ServerSelectorState extends State<ServerSelector> {
  late Future<ServerList> _fetchServersFuture;
  Key _refreshKey = UniqueKey();
  String? _expandedCountry;

  @override
  void initState() {
    super.initState();
    _fetchServersFuture = _fetchServers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServerList>(
      future: _fetchServersFuture,
      key: _refreshKey,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var primaryServers = snapshot.data!.primary;
          var secondaryServers = snapshot.data!.secondary;
          var primaryServersKeys = primaryServers.keys.toList()..sort();
          Map<String, String> secondaryServersCountryToKey = {};
          for (var key in secondaryServers.keys) {
            var country = CountryLocalizations.of(context)?.countryName(countryCode: key) ?? key;
            secondaryServersCountryToKey[country] = key;
          }
          var secondaryServersCountriesSorted = secondaryServersCountryToKey.keys.toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(tr('recommendedServers')),
              ),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: primaryServersKeys.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (var server in primaryServers[primaryServersKeys[index]]!) ...[
                            const Padding(padding: EdgeInsets.only(top: 2)),
                            ServerWidget(server, widget.onServerClick),
                          ]
                        ],
                      ),
                    );
                  }),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(tr('otherServers')),
              ),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _expandedCountry = isExpanded ? secondaryServersCountriesSorted[index] : null;
                  });
                },
                elevation: 0,
                expandIconColor: CustomColors.gray200,
                dividerColor: CustomColors.gray600,
                expandedHeaderPadding: EdgeInsets.zero,
                materialGapSize: 1,
                children: secondaryServersCountriesSorted.map<ExpansionPanel>((String country) {
                  var key = secondaryServersCountryToKey[country]!;
                  var servers = secondaryServers[key]!;
                  return ExpansionPanel(
                    backgroundColor: Colors.transparent,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return InkWell(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: CustomColors.gray700,
                        onTap: () => setState(() {
                          if (_expandedCountry == country) {
                            _expandedCountry = null;
                          } else {
                            _expandedCountry = country;
                          }
                        }),
                        child: ListTile(
                          title: Row(
                            children: [
                              Flag(country: key),
                              const SizedBox(width: 8),
                              Text(country),
                            ],
                          ),
                        ),
                      );
                    },
                    body: Column(
                      children: [
                        for (var server in servers) ...[
                          const Padding(padding: EdgeInsets.only(top: 2)),
                          ServerWidget(server, widget.onServerClick),
                        ]
                      ],
                    ),
                    isExpanded: _expandedCountry == country,
                  );
                }).toList(),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          log('Failed to get servers list', name: 'DicyVPN/Home', error: snapshot.error);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
            child: Column(
              children: [
                Text(tr('cannotLoadServers'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CustomColors.red300)),
                const SizedBox(height: 18),
                Button(
                  onPressed: () {
                    setState(() {
                      _refreshKey = UniqueKey();
                      _fetchServersFuture = _fetchServers();
                    });
                  },
                  theme: CustomButtonTheme.dark,
                  color: CustomButtonColor.blue,
                  size: CustomButtonSize.big,
                  child: Text(tr('cannotLoadServersTryAgain')),
                ),
              ],
            ),
          );
        }

        var verticalPadding = MediaQuery.of(context).size.height / 2.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 32),
              child: const LinearProgressIndicator(),
            ),
          ],
        );
      },
    );
  }

  Future<ServerList> _fetchServers() {
    return API.get().then((api) => api.getServersList());
  }
}
