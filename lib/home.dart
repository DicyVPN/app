import 'package:dicyvpn/ui/components/button.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text('home page'),
            Button(
              onPressed: () {
                Navigator.pushNamed(context, '/logout');
              },
              theme: CustomButtonTheme.dark,
              color: CustomButtonColor.red,
              size: CustomButtonSize.big,
              child: const Text('Logout'),
            ),
            Button(
              onPressed: () {
                Navigator.pushNamed(context, '/login', arguments: 'Your session has expired');
              },
              theme: CustomButtonTheme.dark,
              color: CustomButtonColor.green,
              size: CustomButtonSize.big,
              child: const Text('TEST BUTTON'),
            ),
          ],
        ),
      ),
    );
  }
}
