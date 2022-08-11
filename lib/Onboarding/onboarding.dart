import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:peervendors/AuthenticationScreens/signup_and_login.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/helpers/app_settings.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  static int initialpage = 0;
  int _currentIndex = 0;
  String userLanguage;
  UserPreferences cUP = UserPreferences();
  final Utils utils = Utils();

  setUserLang(String langVal) {
    userLanguage = langVal;
  }

  Future setUserPrefs() async {
    await cUP.setUserPreferences();
  }

  showLocationPermissionsReason() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 15),
            titlePadding: const EdgeInsets.only(top: 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: Colors.white,
            title: Column(children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.location_on,
                  color: Colors.blueAccent,
                ),
                label: Text(
                  AppLocalizations.of(context).permissionsNeeded,
                  style: const TextStyle(fontSize: 24, color: Colors.blue),
                ),
              ),
              Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  width: SizeConfig.screenWidth * 0.7,
                  height: 2.0,
                  color: Colors.black54),
              SizedBox(height: 15)
            ]),
            content: getPermissionsMessage(
                AppLocalizations.of(context).locationPermissionsMessage),
            actions: <Widget>[
              ElevatedButton(
                style: Utils.roundedButtonStyle(),
                child: Text(AppLocalizations.of(context).gotIt,
                    textAlign: TextAlign.center),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        });
  }

  Widget getPermissionsMessage(String p) {
    RegExp regExp = RegExp(
      r'"([\w ' "']+)" '"',
      caseSensitive: false,
      multiLine: false,
    );
    List<String> main = [p.split('"').first];
    Iterable<RegExpMatch> matches = regExp.allMatches(p);
    matches.forEach((element) {
      main.add(element.group(0).toString().replaceAll('"', '').trim());
    });
    main.add(p.split('"').last.trim());
    return SizedBox(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildText(Text(main.first)),
        buildOutlinedButton(main[1].trim()),
        buildOutlinedButton(main[2]),
        buildOutlinedButton(main[3]),
        buildText(Text(main.last, style: const TextStyle(color: Colors.orange)))
      ],
    ));
  }

  Widget buildText(Text child) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        child: child);
  }

  Widget buildOutlinedButton(String text) {
    return OutlinedButton(
      style: Utils.roundedButtonStyle(
          primaryColor: Colors.white, minSize: Size(300, 34), radius: 5),
      child:
          Text(text, style: const TextStyle(color: Colors.blue, fontSize: 17)),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
  }

  final _controller = PageController(
    initialPage: initialpage,
  );
  bool hasChoosedLanguage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

  Widget selectLangTile(String lang, {String langCode = 'en'}) {
    return OutlinedButton(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          primary: Colors.white,
          minimumSize: Size(300, 38)),
      onPressed: () async {
        Provider.of<AppSettings>(context, listen: false).changeLocale(langCode);
        setState(() {
          hasChoosedLanguage = true;
        });
        await cUP.saveString(Constants.peerVendorsLanguage, langCode);
      },
      child:
          Text(lang, style: TextStyle(color: Colors.blue[700], fontSize: 18)),
    );
  }

  TyperAnimatedText buildTyperAnimatedText(String text) {
    return TyperAnimatedText(text,
        textStyle: TextStyle(
            color: Colors.blue[900],
            fontFamily: "Roboto",
            fontStyle: FontStyle.italic,
            fontSize: 30),
        textAlign: TextAlign.center,
        speed: const Duration(milliseconds: 25));
  }

  ScaleAnimatedText buildScaleAnimatedText(String text) {
    return ScaleAnimatedText(text,
        textStyle: TextStyle(
            color: Colors.blue[700], fontFamily: "Roboto", fontSize: 40),
        textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context) {
    Size s = MediaQuery.of(context).size;
    return !hasChoosedLanguage
        ? Scaffold(
            backgroundColor: Colors.blue,
            body: SafeArea(
                child: Center(
                    child: SizedBox(
              height: 300,
              width: s.width,
              child: Card(
                  elevation: 5,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Choose your Language',
                            style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          )),
                      selectLangTile('Kiswahili', langCode: 'sw'),
                      selectLangTile('English', langCode: 'en'),
                      selectLangTile('Francais', langCode: 'fr')
                    ],
                  )),
            ))))
        : Scaffold(
            backgroundColor: Colors.blue,
            body: SafeArea(
              child: Center(
                  child: Container(
                height: 200,
                width: s.width * 0.95,
                color: Colors.blue,
                child: Card(
                    elevation: 5,
                    color: Colors.white,
                    child: Column(children: [
                      Container(
                          color: Colors.indigo[100],
                          child: ListTile(
                              leading: CircleAvatar(
                                  child: Image.asset(
                                      'assets/images/launcher_icon.png')),
                              title: const Text(
                                'Peer Vendors',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontFamily: "Roboto",
                                    fontSize: 35),
                              ))),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: AnimatedTextKit(
                            totalRepeatCount: 1,
                            animatedTexts: [
                              buildTyperAnimatedText(
                                  AppLocalizations.of(context)
                                      .buyAndSellToPeopleAroundYou),
                              // buildTyperAnimatedText("Buy"),
                              // buildTyperAnimatedText("Sell"),
                              // buildTyperAnimatedText("Locally"),
                            ],
                            onFinished: () async {
                              await Future.delayed(const Duration(seconds: 1));
                              await showLocationPermissionsReason();
                              await cUP.setBool(
                                  key: Constants.peerVendorsOnboardingCompleted,
                                  value: true);
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (_) => SignupOrLogin()));
                            },
                          ))
                    ])),
              )),
            ));
  }
}
