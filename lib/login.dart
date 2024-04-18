import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _loading = false;
  String _email = '';
  String _password = '';
  bool _passwordVisible = false;
  final RegExp _emailRegex = RegExp(
      '[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}\\@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _loginAction() {
    if (!_loading && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      login(Navigator.of(context), _email, _password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                                  height: 52,
                                  fit: BoxFit.contain,
                                  semanticLabel: tr('dicyvpnLogo'),
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
                                validator: (value) => (_emailRegex.hasMatch(value!)) ? null : tr('invalidEmailAddress'),
                                onSaved: (value) => _email = value!,
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
                                    tooltip: _passwordVisible ? tr('hidePassword') : tr('showPassword'),
                                  ),
                                ),
                                obscureText: !_passwordVisible,
                                keyboardType: _passwordVisible ? TextInputType.visiblePassword : null,
                                validator: (value) => (value!.length >= 8) ? null : tr('passwordAtLeast8Characters'),
                                onSaved: (value) => _password = value!,
                                onFieldSubmitted: (value) => _loginAction(),
                              ),
                              const SizedBox(height: 16),
                              Button(
                                  theme: CustomButtonTheme.dark,
                                  color: CustomButtonColor.blue,
                                  size: CustomButtonSize.big,
                                  enabled: !_loading,
                                  onPressed: _loginAction,
                                  child: Text(_loading ? "Loading..." : "Login")), // TODO: translate
                              const SizedBox(height: 32),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  InkWell(
                                    onTap: () => launchUrlString('https://dicyvpn.com/prices'),
                                    child: Text(
                                      tr('createAnAccount'),
                                      style: const TextStyle(
                                        color: CustomColors.gray200,
                                        decoration: TextDecoration.underline,
                                        decorationColor: CustomColors.gray200,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => launchUrlString('https://dicyvpn.com/login/request-password-reset'),
                                    child: Text(
                                      tr('recoverYourPassword'),
                                      style: const TextStyle(
                                        color: CustomColors.gray200,
                                        decoration: TextDecoration.underline,
                                        decorationColor: CustomColors.gray200,
                                      ),
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
        ],
      ),
    );
  }

  void login(NavigatorState navigatorState, String email, String password) async {
    setState(() {
      _loading = true;
    });

    try {
      final api = await PublicAPI.get();
      final response = await api.login(email, password);
      await API.setAuthInfo(response.headers);
      navigatorState.popAndPushNamed('/home');
    } on DioException catch (e) {
      if (e.response != null) {
        Response response = e.response!;
        if (response.statusCode == 400 || response.statusCode == 401) {
          _showDialog(tr('invalidEmailOrPassword'));
          return;
        }

        var errorBody = response.data;
        var reply = errorBody['reply'];
        switch (reply['code']) {
          case 'NO_SUBSCRIPTION':
            _showDialog(
              tr('noActiveSubscription'),
              link: tr('urlPrices'),
              linkText: tr('takeALookAtOurPlans'),
            );
            break;
          case 'DEVICES_LIMIT_REACHED':
            _showDialog(
              tr('reachedTheMaximumNumberOfDevices'),
              link: tr('urlAccount'),
              linkText: tr('checkYourDevicesList'),
            );
            break;
          default:
            _showDialog(reply['message']);
        }
      } else {
        _showDialog('Unknown network error, please try again\n\n${e.message}'); // TODO: translate
      }
    } catch (e) {
      _showDialog('Unknown error, please try again\n\n$e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showDialog(String message, {String? link, String? linkText}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            if (link != null)
              TextButton(
                child: Text(tr('dialogClose')),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            TextButton(
              child: Text(linkText ?? tr('dialogClose')),
              onPressed: () {
                if (link != null) {
                  launchUrlString(link);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
