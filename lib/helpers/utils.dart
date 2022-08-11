import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/models/language_model.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Utils {
  static Widget loadingWidget(String message, {String subText = ''}) {
    return Container(
        color: Colors.blue[50],
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                '$message',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              Text(subText)
            ],
          ),
        ));
  }

  static showFailureDialog(BuildContext context, String failureType) {
    String t = failureType == 'Location'
        ? AppLocalizations.of(context).location
        : "Camera, Gallery  ${AppLocalizations.of(context).or} Microphone";
    t = t + ' ' + AppLocalizations.of(context).permissionsNeeded;
    Utils.showToast(context, t, Colors.red);
    Utils.setDialog(context, title: t, children: [
      failureType == 'Location'
          ? Text(AppLocalizations.of(context).locationReason)
          : Text(AppLocalizations.of(context).mediaPermissions),
      const SizedBox(height: 20),
      Text(AppLocalizations.of(context).willYouGrantPermissions)
    ], actions: [
      ElevatedButton.icon(
          style: Utils.roundedButtonStyle(),
          icon: Icon(FontAwesomeIcons.thumbsUp, color: Colors.white),
          onPressed: () async {
            Navigator.of(context).pop();
            if (failureType == 'Location') {
              Addresses.openLocSettings();
            } else {
              Addresses.openAppSettings();
            }
          },
          label: Text(AppLocalizations.of(context).yes)),
      ElevatedButton.icon(
          style: Utils.roundedButtonStyle(primaryColor: Colors.pink[200]),
          icon: Icon(FontAwesomeIcons.thumbsDown, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
          label: Text(AppLocalizations.of(context).no))
    ]);
  }

  static Widget buildContactSupportButton(String email, String prefix,
      String copied, IconData iconData, BuildContext context,
      {UserModel user = null, int categoryId = -1}) {
    return ElevatedButton.icon(
        style: roundedButtonStyle(primaryColor: Colors.green, radius: 5),
        onPressed: () async {
          if (user?.user_id != null && categoryId > -1) {
            ApiRequest.informNeedToVerifyCategory(params: {
              'user_id': user.user_id.toString(),
              'device_ids': user.deviceIds,
              'lang': user.user_lang,
              'username': user.username,
              'firebase_id': user.firebaseUserId,
              'phone_number': user.phoneNumber,
              'email': user.email,
              'category_id': categoryId.toString()
            });
          }
          Clipboard.setData(ClipboardData(text: email));

          String emailScheme = "mailto:$email";
          if (await canLaunch(emailScheme)) {
            await launch(emailScheme);
          } else {
            showToast(context, prefix + ' ' + copied, Colors.green);
          }
        },
        icon: Icon(iconData),
        label: Text(email));
  }

  static BoxDecoration containerBoxDecoration(
      {Color color = Colors.white,
      Color borderColor = Colors.white,
      double radius = 10,
      double borderWidth = 1}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  static TextStyle addressStyle(
      {Color color = Colors.white, double fontSize = 16}) {
    return TextStyle(color: color, fontSize: fontSize, fontFamily: 'Roboto');
  }

  static Widget buildFormHeader(String signInText, Function onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.blue,
              size: 30,
            ),
            onPressed: onPressed,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            signInText,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
        IconButton(
            icon: const Icon(
              Icons.radio,
              color: Colors.transparent,
            ),
            onPressed: () {}),
      ],
    );
  }

  static String getSecondsLeft(int seconds) {
    return seconds < 10 ? '0$seconds' : '$seconds';
  }

  static bool isNumeric(String str) {
    /// check if the string is a number
    var numeric = RegExp(r'^-?[0-9]+$');
    return numeric.hasMatch(str);
  }

  static Widget toggleButtonChild(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center, children: children),
    );
  }

  static Widget progressIndicator({Color color}) {
    return Center(
        child: CircularProgressIndicator(
      color: color,
    ));
  }

  static ButtonStyle roundedButtonStyle(
      {Color primaryColor, Size minSize, double radius = 15}) {
    return ElevatedButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        primary: primaryColor ?? Colors.blue,
        minimumSize: minSize);
  }

  static String getVideoUrl(String reason, String lang) {
    String videosLocation =
        'https://pvendors.s3.eu-west-3.amazonaws.com/support_video/';
    if (reason == 'signUpOrLogIn') {
      return videosLocation + 'login-signup-help-${lang.toLowerCase()}.mp4';
    } else if (reason == 'uploadImage') {
      return videosLocation + 'upload-images-${lang.toLowerCase()}.mp4';
    } else if (reason == 'userAddress' || reason == 'updateLocation') {
      return videosLocation + 'fix-location-isssue-${lang.toLowerCase()}.mp4';
    } else if (reason == 'resizeImages') {
      return videosLocation + 'resize-images-${lang.toLowerCase()}.mp4';
    } else if (reason == 'howToUseApp') {
      return videosLocation + 'general-help-${lang.toLowerCase()}.mp4';
    } else {
      return videosLocation + 'general-help-${lang.toLowerCase()}.mp4';
    }
  }

  static Widget buildPageSummary(String message, {Color color = Colors.black}) {
    return Container(
        padding: const EdgeInsets.all(3.0),
        decoration: Utils.containerBoxDecoration(
            radius: 5, borderColor: Colors.blue[50], borderWidth: 5),
        child: Text(
          message,
          textAlign: TextAlign.justify,
          style: TextStyle(color: color, fontSize: 16),
        ));
  }

  static Widget buildBottomBar({Color color = Colors.blue}) {
    return BottomAppBar(
      color: color,
      child: Container(height: 47),
    );
  }

  static String shortenText(String text, {int desiredLength = 30}) {
    return text.length > desiredLength
        ? text.substring(0, desiredLength) + ' ...'
        : text;
  }

  List<BoxShadow> boxShadows() {
    return const [
      BoxShadow(
          color: Colors.black26,
          offset: Offset(4.0, 4.0),
          blurRadius: 10,
          spreadRadius: 1.0),
      BoxShadow(
          color: Colors.white,
          offset: Offset(-4.0, -4.0),
          blurRadius: 5,
          spreadRadius: 1.0)
    ];
  }

  static Widget buildSeparator(double screenWidth, {bool isSmaller = false}) {
    return Center(
        child: Container(
      padding: EdgeInsets.only(top: 30.0, bottom: 8.0),
      width: isSmaller ? screenWidth * 0.6 : screenWidth * 0.8,
      height: 2.0,
      color: Colors.black54,
      margin: EdgeInsets.only(top: 4.0),
    ));
  }

  static Widget buildText(String text,
      {double fontSize = 16,
      Color color = Colors.black,
      bool centrallize = false}) {
    return Text(
      text,
      textAlign: centrallize ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontSize: fontSize, color: color),
    );
  }

  static Widget virticalSizedBox({double height = 12}) {
    return SizedBox(
      height: height,
    );
  }

  static Widget buildStack(
      double screenWidth, double screenHeight, String profileImage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: screenHeight * 0.33,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/springbackground.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
            bottom: 0, child: buildProfileImage(screenWidth, profileImage))
      ],
    );
  }

  static Widget buildProfileImage(double screenWidth, String profileImage) {
    return Center(
      child: Container(
        width: screenWidth * 0.5,
        height: screenWidth * 0.5,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: profileImage.startsWith('https://')
                ? NetworkImage(profileImage)
                : FileImage(File(profileImage)),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.2),
          border: Border.all(
            color: Colors.white,
            width: 10.0,
          ),
        ),
      ),
    );
  }

  static Widget messageWidget(BuildContext context, String message) {
    return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$message',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontFamily: 'Roboto'),
                ),
              )
            ],
          ),
        ));
  }

  static void showToast(BuildContext context, String text, Color bgColor,
      {int duration = 4}) {
    final mySnackBar = SnackBar(
        content: Text(text),
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: bgColor);
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar);
  }

  static List<LanguageModel> languages() {
    List<LanguageModel> listLanguages = [
      LanguageModel(languageCode: 'en', languageName: 'English'),
      LanguageModel(languageCode: 'fr', languageName: 'French'),
      LanguageModel(languageCode: 'sw', languageName: 'Swahili')
    ];
    return listLanguages;
  }

  static void setDialog(BuildContext context,
      {@required String title,
      @required List<Widget> children,
      @required List<Widget> actions,
      bool barrierDismissible = true,
      TextStyle titleStyle = const TextStyle(),
      EdgeInsets padding =
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0)}) {
    AlertDialog dailog = AlertDialog(
        insetPadding: padding,
        backgroundColor: const Color(0xFFE9EDF0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13))),
        title: Text(title, textAlign: TextAlign.center, style: titleStyle),
        content: SingleChildScrollView(
          child: ListBody(children: children),
        ),
        actions: actions);
    showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => dailog);
    //builder: (BuildContext context) => dailog);
  }

  static BorderRadius borderRadius({double radius = 10}) {
    return BorderRadius.circular(10.0);
  }

  static Widget customButton(
      double width, String centertext, Function onPressed,
      {Color color = Colors.blue}) {
    return ElevatedButton(
        style:
            roundedButtonStyle(primaryColor: color, minSize: Size(width, 38)),
        child: Text(centertext,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        onPressed: onPressed);
  }
}
