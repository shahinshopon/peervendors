import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info/package_info.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/app_feedback.dart';

class HelpScreen extends StatefulWidget {
  final UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  HelpScreen({Key key, @required this.currentUser, @required this.cUP})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MyHelpScreen();
}

class MyHelpScreen extends State<HelpScreen> {
  String version;

  @override
  void initState() {
    getPackageInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle boldText = const TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(AppLocalizations.of(context).helpSupport),
          centerTitle: true,
          backgroundColor: Colors.blue,
          elevation: 5,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  buildCard(ListTile(
                      title: Text(AppLocalizations.of(context).rateUs,
                          style: boldText),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AppFeedback(
                                    reviewerId: widget.currentUser.user_id)));
                      })),
                  buildCard(ListTile(
                    title: Text(AppLocalizations.of(context).version,
                        style: boldText),
                    trailing: Text(version ?? ''),
                    onTap: () {},
                  ))
                ]))),
        bottomNavigationBar: Utils.buildBottomBar());
  }

  Widget buildCard(Widget child) {
    return Card(elevation: 4, child: child);
  }

  getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() => version = packageInfo.version);
  }
}
