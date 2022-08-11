import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peervendors/helpers/app_settings.dart';
import 'package:peervendors/helpers/app_version.dart';
import 'package:provider/provider.dart';
import 'package:peervendors/Onboarding/onboarding.dart';
import 'package:peervendors/AuthenticationScreens/signup_and_login.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic> pushNotificationData;
  SplashScreen({Key key, @required this.pushNotificationData})
      : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthService authService = AuthService();
  UserPreferences cUP = UserPreferences();
  bool isLoading = true;
  String _splashReason;

  Future<String> getInfo({bool checkForUpdates = true}) async {
    await cUP.setUserPreferences();
    String t = cUP.getString(Constants.peerVendorsLanguage);
    if (t?.length == 2) {
      Provider.of<AppSettings>(context, listen: false).changeLocale(t);
    }
    if (checkForUpdates) {
      int l = cUP.getTimeWhenEventHppened(
          eventName: Constants.peerVendorsCheckForUpdates);
      if (l < 100 ||
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(l))
                  .inDays >
              1) {
        var b = await Future.wait([
          ApiRequest.getAppVersion(),
          AppVersion.getAppVersion(),
          cUP.setTimeWhenEventHappened(
              eventName: Constants.peerVendorsCheckForUpdates)
        ]);
        if (b[0] != b[1] && !b.contains(null)) {
          return '${b[0]}|${b[1]}';
        }
      }
    }
    bool onboardingHasBeenCompleted =
        cUP.getBool(key: Constants.peerVendorsOnboardingCompleted) ?? false;
    if (!onboardingHasBeenCompleted) {
      return 'completeOnboarding';
    } else {
      bool isAccountStatus =
          cUP.getBool(key: Constants.peerVendorsAccountStatus) ?? false;
      UserModel extractedUser = cUP.getCurrentUser();
      if (isAccountStatus && extractedUser != null) {
        await authService.signInWithEmailAndPassword(
            extractedUser.email.trim(), extractedUser.email.trim());
        return 'accountStatusAndUser';
      } else {
        return 'loginSignUp';
      }
    }
  }

  Future checkFirstSeen() async {
    _splashReason = await getInfo();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    checkFirstSeen().then((value) {
      navigateToPages(_splashReason);
    });
  }

  chooseNotToUpdateApp() async {
    String result = await getInfo(checkForUpdates: false);
    navigateToPages(result);
  }

  void navigateToPages(String reason) {
    if (reason == 'completeOnboarding') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => OnboardingScreen()));
    } else if (reason == "accountStatusAndUser") {
      if (widget.pushNotificationData != null &&
          widget.pushNotificationData.length > 1) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => BottomNavController(
                      homePageProducts: null,
                      startTab: 3,
                    )));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => BottomNavController(
                      homePageProducts: null,
                    )));
      }
    } else if (reason != null && reason.contains('|')) {
      setState(() {
        isLoading = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignupOrLogin()));
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return isLoading
        ? splashScreen()
        : Scaffold(
            backgroundColor: Colors.blue,
            body: SafeArea(
              child: Center(
                  child: SizedBox(
                      height: 350,
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 30),
                        child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 30),
                            child: Column(children: [
                              Center(
                                  child: Column(children: [
                                Utils.buildText(
                                    AppLocalizations.of(context)
                                        .updatesAvailable,
                                    color: Colors.blueAccent,
                                    fontSize: 20),
                                Utils.buildSeparator(
                                    SizeConfig.screenWidth * 0.75),
                                const SizedBox(height: 15),
                                Text(
                                  AppLocalizations.of(context)
                                      .updateAppMessage
                                      .replaceAll(
                                          '100', _splashReason.split('|').last)
                                      .replaceAll('200',
                                          _splashReason.split('|').first),
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                        style: Utils.roundedButtonStyle(
                                            primaryColor: Colors.pink),
                                        onPressed: chooseNotToUpdateApp,
                                        child: Text(AppLocalizations.of(context)
                                            .maybeLater)),
                                    ElevatedButton(
                                        style: Utils.roundedButtonStyle(
                                            primaryColor: Colors.green),
                                        onPressed: () async {
                                          try {
                                            await launch(
                                                'https://play.google.com/store/apps/details?id=com.peervendors');
                                          } catch (e) {
                                            chooseNotToUpdateApp();
                                          }
                                        },
                                        child: Text(AppLocalizations.of(context)
                                            .updateNow))
                                  ],
                                )
                              ]))
                            ])),
                      ))),
            ),
          );
  }

  Widget splashScreen() {
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: FractionallySizedBox(
          heightFactor: 0.4,
          widthFactor: 0.4,
          child: Image.asset("assets/images/launcher_icon.png"),
        ),
      ),
    ));
  }
}
