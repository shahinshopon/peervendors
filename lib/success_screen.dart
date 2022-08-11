import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';

import 'helpers/utils.dart';

class SuccessScreen extends StatefulWidget {
  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((value) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => BottomNavController()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF090232),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: SizeConfig.screenHeight * 0.3,
                width: SizeConfig.screenWidth * 0.3,
                child: Image.asset(
                  "assets/images/lightbulb.png",
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                AppLocalizations.of(context).authenticationSuccessful,
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 7,
                    color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
