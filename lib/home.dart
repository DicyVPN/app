import 'dart:developer';

import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _loading = true;
  Map<String, List<Server>> _primaryServers = {};
  Map<String, List<Server>> _secondaryServers = {};

  @override
  Widget build(BuildContext context) {
    var primaryServersKeys = _primaryServers.keys.toList();
    var secondaryServersKeys = _secondaryServers.keys.toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Button(
                      onPressed: _fetchServers,
                      theme: CustomButtonTheme.dark,
                      color: CustomButtonColor.blue,
                      size: CustomButtonSize.big,
                      child: const Text('Load servers'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Text(tr('recommendedServers')),
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 4)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Container(
                      height: 50,
                      color: Colors.amber,
                      child: Center(child: Text('Entry ${primaryServersKeys[index]}')),
                    );
                  },
                  childCount: primaryServersKeys.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 4)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(tr('otherServers')),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 4)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Container(
                      height: 50,
                      color: Colors.amber,
                      child: Center(child: Text('Secondary: ${secondaryServersKeys[index]}')),
                    );
                  },
                  childCount: secondaryServersKeys.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 16))
          ],
        ),
      ),
    );
  }

  void _fetchServers() async {
    setState(() {
      _loading = true;
    });

    var api = await API.get();
    try {
      var serverList = await api.getServersList();
      setState(() {
        _loading = false;
        _primaryServers = serverList.primary;
        _secondaryServers = serverList.secondary;
      });
    } catch (e) {
      log('Failed to get servers list', name: 'DicyVPN/Home', error: e);
      setState(() {
        _loading = false;
      });
    }
  }
}
