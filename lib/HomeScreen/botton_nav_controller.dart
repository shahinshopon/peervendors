import 'dart:io';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:animations/animations.dart';

import 'Nav_Bar_Pages/account_screen.dart';
import 'Nav_Bar_Pages/chat_history.dart';
import 'Nav_Bar_Pages/home_screen.dart';
import 'Nav_Bar_Pages/myads_screen.dart';
import 'Nav_Bar_Pages/sell_screen.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavController extends StatefulWidget {
  final ProductListForHomePage homePageProducts;
  final int startTab;
  Map<String, dynamic> order;
  bool intend2editProfile;
  BottomNavController(
      {Key key,
      this.homePageProducts,
      this.startTab,
      this.order,
      this.intend2editProfile})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => BottomNavControllerState();
}

class BottomNavControllerState extends State<BottomNavController> {
  int _tabSelectedIndex = 0;
  bool hasLoadedUser = false;
  UserPreferences cUP = UserPreferences();
  DateTime currentBackPressTime;
  UserModel currentUser;
  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    if (widget.startTab != null) {
      _tabSelectedIndex = widget.startTab;
    }
    if (widget.order != null) {
      _tabSelectedIndex = 1;
    }
    setUserPrefs();
  }

  Future setUserPrefs() async {
    await cUP.setUserPreferences();
    currentUser = cUP.getCurrentUser();
    setState(() {
      hasLoadedUser = true;
    });
  }

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return HomeScreen(
            homePageProducts: widget.homePageProducts,
            currentUser: currentUser,
            cUP: cUP);
      case 1:
        return MyAdsScreen(
            currentUser: currentUser, cUP: cUP, order: widget.order);
      case 2:
        return SellScreen();
      case 3:
        return ChatLoginScreen(
            isBackArrow: false,
            searchDetails: const {},
            currentUser: currentUser,
            cUP: cUP);

      case 4:
        return AccountScreen(
            cUP: cUP,
            currentUser: currentUser,
            intend2editProfile: widget.intend2editProfile == true);

      default:
        return HomeScreen(
            homePageProducts: widget.homePageProducts,
            currentUser: currentUser,
            cUP: cUP);
    }
  }

  @override
  Widget build(BuildContext context) {
    return hasLoadedUser
        ? WillPopScope(
            onWillPop: () async {
              if (_tabSelectedIndex != 0) {
                _tabSelectedIndex = 0;
                setState(() {});
                return !Platform.isAndroid;
              } else {
                Utils.setDialog(context,
                    title: AppLocalizations.of(context).exitApp,
                    children: [
                      Text(AppLocalizations.of(context).closeAndExitApp,
                          textAlign: TextAlign.center),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                    actions: [
                      ElevatedButton(
                          style: Utils.roundedButtonStyle(
                              primaryColor: Colors.blue),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context).no)),
                      ElevatedButton(
                          style: Utils.roundedButtonStyle(
                              primaryColor: Colors.pink[200]),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 1000),
                                () {
                              SystemChannels.platform
                                  .invokeMethod('SystemNavigator.pop');
                            });
                          },
                          child: Text(AppLocalizations.of(context).yes))
                    ]);
              }
              //if on android, do nothing. On IOS return.
              return !Platform.isAndroid;
            },
            child: Scaffold(
                backgroundColor: Colors.blue,
                bottomNavigationBar: SafeArea(
                    child: CurvedNavigationBar(
                  index: _tabSelectedIndex,
                  buttonBackgroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  color: Colors.blue,
                  height: 50,
                  animationDuration: const Duration(milliseconds: 600),
                  onTap: (index) {
                    setState(() {
                      _tabSelectedIndex = index;
                    });
                  },
                  items: [
                    buildNavItem(Icons.home, AppLocalizations.of(context).home),
                    buildNavItem(
                        Icons.star, AppLocalizations.of(context).myAds),
                    buildNavItem(
                        Icons.camera_alt, AppLocalizations.of(context).sell),
                    buildNavItem(
                        Icons.message, AppLocalizations.of(context).chat),
                    buildNavItem(
                        Icons.person, AppLocalizations.of(context).account),
                  ],
                )),
                body: SafeArea(
                  child: PageTransitionSwitcher(
                    transitionBuilder:
                        (child, primaryAnimation, secondaryAnimation) =>
                            FadeThroughTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    ),
                    child: _getDrawerItemWidget(_tabSelectedIndex),
                  ),
                )))
        : const SizedBox.shrink();
  }

  Widget buildNavItem(IconData iconData, String buttonText) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
          child: Icon(
            iconData,
            size: 22,
            color: Colors.white,
          ),
        ),
        Text(
          buttonText,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 10, color: Colors.white),
        ),
      ],
    );
  }
}
