import 'dart:developer';

import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Material(
            color: CustomColors.gray800,
            elevation: 4,
            textStyle: TextStyle(color: CustomColors.gray200),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ServerSelector(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServerSelector extends StatefulWidget {
  const ServerSelector({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ServerSelectorState();
  }
}

class _ServerSelectorState extends State<ServerSelector> {
  late Future<ServerList> _fetchServersFuture;
  Key _refreshKey = UniqueKey();

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
          var primaryServersKeys = primaryServers.keys.toList();
          var secondaryServersKeys = secondaryServers.keys.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(tr('recommendedServers')),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: primaryServersKeys.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 50,
                      color: Colors.amber,
                      child: Center(child: Text('Entry ${primaryServersKeys[index]}')),
                    );
                  }),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(tr('otherServers')),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: secondaryServersKeys.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    color: Colors.amber,
                    child: Center(child: Text('Secondary: ${secondaryServersKeys[index]}')),
                  );
                },
              ),
            ],
          );
        } else if (snapshot.hasError) {
          log('Failed to get servers list', name: 'DicyVPN/Home', error: snapshot.error);
          return Padding(
            padding: const EdgeInsets.all(32),
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

        return const Padding(
          padding: EdgeInsets.all(32),
          child: LinearProgressIndicator(),
        );
      },
    );
  }

  Future<ServerList> _fetchServers() {
    return API.get().then((api) => api.getServersList());
  }
}
