import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/HomeScreen/Help_Support/delete_account_feedback.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/HomeScreen/Help_Support/help.dart';
import 'package:peervendors/AuthenticationScreens/signup_and_login.dart';
import 'package:peervendors/HomeScreen/Nav_Bar_Pages/view_profile.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/app_settings.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/app_feedback.dart';
import 'package:peervendors/views/edit_profile.dart';
import 'package:peervendors/views/contact_us.dart';
import 'package:peervendors/views/privacy_or_faqs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

class SettingsModel {
  IconData trailingIcon;
  String title;
  String subTitle;
  dynamic leading;
  bool isImage;
  Color color;
  SettingsModel(
      {this.trailingIcon,
      this.title,
      this.subTitle,
      this.leading,
      this.isImage = false,
      this.color = Colors.black});
}

class AccountScreen extends StatefulWidget {
  UserModel currentUser;
  bool intend2editProfile;
  UserPreferences cUP = UserPreferences();
  AccountScreen(
      {Key key,
      @required this.intend2editProfile,
      @required this.cUP,
      @required this.currentUser})
      : super(key: key);

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  List<SettingsModel> listSettings;
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  listOfSettings(BuildContext context) {
    final setting1 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).privacyPolicy,
        subTitle: AppLocalizations.of(context).legalAndPrivacyInfo,
        leading: Icons.security);

    final setting2 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).helpSupport,
        subTitle: AppLocalizations.of(context).helpCenterAndLegalTerms,
        leading: Icons.help);

    final setting3 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).shareApp,
        subTitle: AppLocalizations.of(context).inviteAppToFriends,
        leading: Icons.share);

    final setting4 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).language,
        subTitle: AppLocalizations.of(context).language,
        leading: Icons.language_outlined);

    final setting5 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).logout,
        subTitle: AppLocalizations.of(context).logout,
        leading: Icons.logout);

    final setting6 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).deactivateAccount,
        subTitle: AppLocalizations.of(context).deactivateAccount,
        leading: Icons.delete_forever_outlined);

    final setting7 = SettingsModel(
        trailingIcon: Icons.arrow_forward_ios_outlined,
        title: AppLocalizations.of(context).editProfile,
        subTitle: AppLocalizations.of(context).editProfile,
        leading: Icons.account_circle_outlined);

    final setting8 = SettingsModel(
        leading: Image.asset("assets/images/FAQs.png", height: 35, width: 35),
        title: AppLocalizations.of(context).faq,
        subTitle: AppLocalizations.of(context).seeFaqsAndContactSupport,
        trailingIcon: Icons.arrow_forward_ios_outlined,
        isImage: true);

    final setting9 = SettingsModel(
        leading: Icons.analytics_sharp,
        title: AppLocalizations.of(context).accountMetrics,
        subTitle: AppLocalizations.of(context).accountMetrics,
        trailingIcon: Icons.arrow_forward_ios_outlined);

    final setting10 = SettingsModel(
      leading: FontAwesomeIcons.envelope,
      title: AppLocalizations.of(context).contactUs,
      subTitle: AppLocalizations.of(context).contactUs,
      trailingIcon: Icons.arrow_forward_ios_outlined,
    );

    final setting11 = SettingsModel(
        leading:
            Image.asset("assets/images/appreview.png", height: 35, width: 35),
        title: AppLocalizations.of(context).rateUs,
        subTitle: AppLocalizations.of(context).writeAReview,
        trailingIcon: Icons.arrow_forward_ios_outlined,
        isImage: true);

    final setting12 = SettingsModel(
        leading: FontAwesomeIcons.searchLocation,
        title: AppLocalizations.of(context).fixMyLocationProblem,
        subTitle: AppLocalizations.of(context).trobleshootLocation,
        trailingIcon: Icons.arrow_forward_ios_outlined,
        color: Colors.red);
    listSettings = [
      setting3,
      setting2,
      setting10,
      setting11,
      setting9,
      setting7,
      setting4,
      setting8,
      setting1,
      setting5,
      setting6,
      setting12
    ];
  }

  saveLanguageAndMoveOn(BuildContext context,
      {@required String languageCode}) async {
    String currentLang = AppLocalizations.of(context).localeName;
    if (currentLang != languageCode) {
      Provider.of<AppSettings>(context, listen: false)
          .changeLocale(languageCode);
      widget.currentUser.user_lang = languageCode;
      widget.cUP.saveUser(widget.currentUser);
      if (widget.currentUser.user_lang != languageCode) {
        ApiRequest.changeUserLanguage(
            userId: widget.currentUser.user_id, newLangCode: languageCode);

        await widget.cUP
            .saveString(Constants.peerVendorsLanguage, languageCode);
      }
    }
    Navigator.of(context).pop();
  }

  saveAddress(Map<String, dynamic> address, BuildContext context) async {
    await widget.cUP
        .saveString(Constants.peerVendorsCurrentAddress, json.encode(address));
    Utils.showToast(
        context, '👍🏾 ${AppLocalizations.of(context).gotIt}', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    listOfSettings(context);
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: Text(
            '${AppLocalizations.of(context).account} ${AppLocalizations.of(context).settings}'),
        centerTitle: true,
        elevation: 5,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(4),
        child: Column(
          children: [
            Utils.buildPageSummary(
              AppLocalizations.of(context).accountSettingsMessage,
            ),
            // TextButton(
            //   child: const Text(
            //     'Bonabéri	Littoral',
            //     style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
            //   ),
            //   onPressed: () async {
            //     // UserModel user = await ApiRequest.isEmailOrPhoneRegistered(
            //     //     email: 'ndesamuelmbah@gmail.com');
            //     print('address: ${widget.currentUser.toJson()}');
            //   },
            // ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                primary: true,
                scrollDirection: Axis.vertical,
                shrinkWrap: false,
                itemCount: listSettings.length,
                itemBuilder: (context, index) {
                  Color color = widget.intend2editProfile == false && index == 5
                      ? Colors.green[200]
                      : Colors.white;
                  return Card(
                      color: color,
                      child: ListTile(
                        leading: listSettings[index].isImage
                            ? listSettings[index].leading
                            : Icon(
                                listSettings[index].leading,
                                color: listSettings[index].color,
                                size: 35,
                              ),
                        title: Text(
                          listSettings[index].title,
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          listSettings[index].subTitle,
                          style: const TextStyle(
                              color: colorGrey700, fontSize: 13),
                        ),
                        trailing: Icon(
                          listSettings[index].trailingIcon,
                          color: colorGrey700,
                          size: 16,
                        ),
                        onLongPress: () async {
                          if (index == 11) {
                            Map<String, dynamic> currentAddress =
                                await Addresses.getUsersCurrentAddress();
                            if (currentAddress?.isNotEmpty == true) {
                              saveAddress(currentAddress, context);
                            } else {
                              currentAddress =
                                  await Addresses.getAddressFromBackend();

                              if (currentAddress?.isNotEmpty == true) {
                                saveAddress(currentAddress, context);
                              } else {
                                Utils.showFailureDialog(context, "Location");
                              }
                            }
                          }
                        },
                        onTap: () async {
                          if (index == 11) {
                            final String permissionsType =
                                await Addresses.isLocationServiceEnabled();
                            if (permissionsType == 'geolocation') {
                              final locationPermissions = await Addresses
                                  .getLocationPermissionsGeolocation();
                              if (locationPermissions != true) {
                                Utils.showFailureDialog(context, "Location");
                              } else {
                                Utils.showToast(
                                    context,
                                    AppLocalizations.of(context)
                                        .grantedLocationPermissions,
                                    Colors.blue,
                                    duration: 6);
                              }
                            } else if (permissionsType == 'location') {
                              final locationPermissions = await Addresses
                                  .getLocationPermissionsLocation();
                              if (locationPermissions != true) {
                                Utils.showFailureDialog(context, "Location");
                              } else {
                                Utils.showToast(
                                    context,
                                    AppLocalizations.of(context)
                                        .grantedLocationPermissions,
                                    Colors.blue,
                                    duration: 6);
                              }
                            } else {
                              Utils.showFailureDialog(context, "Location");
                            }
                          }
                          if (index == 6) {
                            setDialog(context,
                                title: AppLocalizations.of(context).language,
                                children: <Widget>[
                                  Text(AppLocalizations.of(context)
                                      .select_language),
                                ],
                                actions: <Widget>[
                                  buildLanguage('English', 'en', context),
                                  buildLanguage('French', 'fr', context),
                                  buildLanguage('Kiswahili', 'sw', context)
                                ]);
                          } else if (index == 9) {
                            setDialog(context,
                                title: AppLocalizations.of(context).logout,
                                children: <Widget>[
                                  Text(AppLocalizations.of(context)
                                      .areYouSureWantToLogout),
                                ],
                                actions: <Widget>[
                                  ElevatedButton(
                                    style: Utils.roundedButtonStyle(
                                        primaryColor: Colors.green),
                                    child: Text(
                                        AppLocalizations.of(context).cancel),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: Utils.roundedButtonStyle(
                                        primaryColor: Colors.pink),
                                    child: Text(
                                        AppLocalizations.of(context).logout),
                                    onPressed: signOutUser,
                                  )
                                ]);
                          } else if (index == 10) {
                            setDialog(context,
                                title: AppLocalizations.of(context)
                                    .deactivateAccount,
                                children: <Widget>[
                                  Text(AppLocalizations.of(context)
                                      .deactivateAccountAndDeleteData),
                                ],
                                actions: <Widget>[
                                  ElevatedButton(
                                    style: Utils.roundedButtonStyle(
                                        primaryColor: Colors.green),
                                    child: Text(
                                        AppLocalizations.of(context).cancel),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: Utils.roundedButtonStyle(
                                        primaryColor: Colors.pink),
                                    child: Text(AppLocalizations.of(context)
                                        .deactivate),
                                    onPressed: deactivateAccount,
                                  )
                                ]);
                          } else if (index == 0) {
                            Share.share(
                                'https://play.google.com/store/apps/details?id=com.peervendors',
                                subject: AppLocalizations.of(context)
                                    .installPeerVendors);
                          } else {
                            dynamic root;
                            if (index == 8) {
                              root = PrivacyOrFAQs(isPrivacy: true);
                            } else if (index == 1) {
                              root = HelpScreen(
                                  currentUser: widget.currentUser,
                                  cUP: widget.cUP);
                            } else if (index == 5) {
                              root = EditProfile(
                                  currentUser: widget.currentUser,
                                  cUP: widget.cUP,
                                  intendToAddPhone: false);
                            } else if (index == 7) {
                              root = PrivacyOrFAQs(isPrivacy: false);
                            } else if (index == 4) {
                              root = UserProfilePage(
                                  currentUser: widget.currentUser,
                                  isEditable: true,
                                  cUP: widget.cUP);
                            } else if (index == 2) {
                              root = ContactUs(
                                  currentUser: widget.currentUser,
                                  cUP: widget.cUP);
                            } else if (index == 3) {
                              root = AppFeedback(
                                  reviewerId: widget.currentUser.user_id);
                            }
                            if (root != null) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => root));
                            }
                          }
                        },
                      ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void signOutUser() async {
    widget.cUP.setAccountStatusActive(isActive: false);
    int resetTime = DateTime.now()
        .add(const Duration(seconds: -800))
        .millisecondsSinceEpoch;
    await Future.wait([
      widget.cUP.saveString(Constants.peerVendorsLastVCodes, ''),
      widget.cUP.setInt(Constants.whenLastVerificationCodeWasSent, resetTime),
      authService.signOut()
    ]);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignupOrLogin()),
      (route) => false,
    );
  }

  void deactivateAccount() async {
    // DeleteAccountFeedbackScreen
    await ApiRequest.deactivateAccount({
      'user_id': widget.currentUser.user_id.toString(),
      'firebase_id': widget.currentUser.firebaseUserId
    });
    await authService.signOut();
    widget.cUP.clearPrefs();
    Utils.showToast(
        context,
        AppLocalizations.of(context).deactivatedAccountMessage.split('. ').last,
        Colors.green);

    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DeleteAccountFeedbackScreen(
                  currentUser: widget.currentUser,
                )));
  }

  Widget buildLanguage(
      String languageName, String languageCode, BuildContext context) {
    return ElevatedButton(
      style: Utils.roundedButtonStyle(),
      child: Text(languageName),
      onPressed: () {
        saveLanguageAndMoveOn(context, languageCode: languageCode);
      },
    );
  }

  void setDialog(BuildContext context,
      {@required String title,
      @required List<Widget> children,
      @required List<Widget> actions}) {
    AlertDialog dailog = AlertDialog(
        alignment: Alignment.center,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13))),
        title: Center(child: Text(title)),
        content: SingleChildScrollView(
          child: ListBody(children: children),
        ),
        actions: actions);
    showDialog(context: context, builder: (BuildContext context) => dailog);
  }
}
