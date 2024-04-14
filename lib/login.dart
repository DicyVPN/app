import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _loading = false;
  String _email = '';
  bool loading = false;
  String email = "";
  String password = "";
  bool _passwordVisible = false;
  bool openDialog = false;
  String dialogMessage = "";
  String dialogLink = "";
  String dialogLinkText = "";
  final RegExp _emailRegex = RegExp(
      '[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}\\@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _doSomething() {
    setState(() {
      _loading = true;
      _email = 'hello@test.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Transform.scale(
          scale: 1.5,
          origin: const Offset(0, -40),
          child: SvgPicture.asset(
            'assets/images/world_map.svg',
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(CustomColors.gray400.withOpacity(0.7), BlendMode.srcIn),
            height: MediaQuery.of(context).size.height,
            excludeFromSemantics: true,
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Material(
                    color: CustomColors.gray600,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Image.asset(
                                'assets/images/full_logo.png',
                                height: 52.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: tr('email'),
                                filled: true,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              // TODO change or translate
                              validator: (value) => (_emailRegex.hasMatch(value!)) ? null : "Invalid email address",
                              onSaved: (value) => email = value!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: tr('password'),
                                filled: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                ),
                              ),
                              obscureText: !_passwordVisible,
                              keyboardType: _passwordVisible ? TextInputType.visiblePassword : null,
                              validator: (value) =>
                                  (value!.length >= 8) ? null : "Password must be at least 8 characters long",
                              onSaved: (value) => password = value!,
                              // TODO: same action as 'login button'
                              //onFieldSubmitted: (value) => print("hello $str"),
                            ),
                            const SizedBox(height: 16),
                            Button(
                              theme: CustomButtonTheme.dark,
                              color: CustomButtonColor.blue,
                              size: CustomButtonSize.big,
                              enabled: !loading,
                              child: Text(loading ? "Loading..." : "Login"),
                              onPressed:
                                  // TODO: do something
                                  // loading ? null : () => _formKey.currentState!.save() ? login(email, password) : null,
                                  () => {},
                            ),
                            const SizedBox(height: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  tr('createAnAccount'),
                                  style: const TextStyle(
                                    color: CustomColors.gray200,
                                    decoration: TextDecoration.underline,
                                    decorationColor: CustomColors.gray200,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr('recoverYourPassword'),
                                  style: const TextStyle(
                                    color: CustomColors.gray200,
                                    decoration: TextDecoration.underline,
                                    decorationColor: CustomColors.gray200,
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
              ),
            ),
          ),
        ),
        // Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: <Widget>[
        //       Text(
        //         'LOADING: $_loading\n\nYou have pushed the button this many times:',
        //       ),
        //       Text(
        //         _email,
        //         style: Theme.of(context).textTheme.headlineMedium,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
