import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:peervendors/AuthenticationScreens/otp_screen.dart';
import 'package:peervendors/AuthenticationScreens/registration_screen.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/form_validators.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formkey = GlobalKey<FormState>();
  String _email, _phone, checkEmailRegistered, _countryDialCode, countryCode;
  final _emailController = TextEditingController();
  final _phonenumbercontroller = TextEditingController();
  final _otpController = TextEditingController();
  String doesEmailExist, doesPhoneNumberExists;
  UserModel currentUser;
  AuthService authService = AuthService();
  final FirebaseAuth authInstance = FirebaseAuth.instance;
  UserPreferences cUP = UserPreferences();
  List<bool> _signInSelectedMethods = [true, false];
  String registrationType = 'phone';
  String phoneRegex = '\d{7,7}';
  bool isLoading = false;
  String newDeviceId;
  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    setUserPrefs();
  }

  @override
  void dispose() {
    _phonenumbercontroller.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void setLoadingStatus(bool status) {
    setState(() {
      isLoading = status;
    });
  }

  Future setUserPrefs() async {
    await cUP.setUserPreferences();
    currentUser = cUP.getCurrentUser();
    if (currentUser?.country_code != null) {
      Map<dynamic, dynamic> chooseCountry =
          Constants.countryLookupMap[currentUser.country_code.toUpperCase()];
      setState(() {
        countryCode = currentUser.country_code.toUpperCase();
        phoneRegex = chooseCountry['mobile_phone_regex_pattern'];
        _countryDialCode = chooseCountry['dial_code'];
      });
    }
    try {
      newDeviceId = await FirebaseMessaging.instance.getToken();
    } catch (e) {}
    setState(() {});
    if (cUP.canExtractAddress(10)) {
      Map<String, dynamic> currentUsersAddress =
          await Addresses.getAddressFromBackend();
      if (currentUsersAddress != null && currentUsersAddress.length > 2) {
        cUP.saveString(Constants.peerVendorsCurrentAddress,
            json.encode(currentUsersAddress));
        cUP.setTimeWhenEventHappened(
            eventName: Constants.whenAddresLastRequested);
        if (currentUsersAddress['country_code'] != null &&
            countryCode == null) {
          countryCode = currentUsersAddress['country_code'];
          var choosenCountry = Constants.countryLookupMap[countryCode];
          if (choosenCountry != null) {
            phoneRegex = choosenCountry['mobile_phone_regex_pattern'];
            _countryDialCode = choosenCountry['dial_code'];
          }
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue,
        body: SafeArea(
            child: isLoading
                ? Utils.loadingWidget(
                    AppLocalizations.of(context).loadingPleaseWait)
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: Utils.containerBoxDecoration(radius: 15),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: <Widget>[
                              AspectRatio(
                                aspectRatio: 0.75,
                                child: Form(
                                  key: _formkey,
                                  child: Column(
                                    children: <Widget>[
                                      const SizedBox(height: 15),
                                      Utils.buildFormHeader(
                                          AppLocalizations.of(context).sign_in,
                                          () {
                                        Navigator.pop(context);
                                      }),
                                      const SizedBox(height: 15),
                                      buildToggleButtons(),
                                      countryCode == "OT" &&
                                              registrationType != 'email'
                                          ? Text(
                                              AppLocalizations.of(context)
                                                  .emailRequired,
                                              style: TextStyle(
                                                  color: Colors.redAccent[200]))
                                          : Container(height: 2),
                                      const SizedBox(height: 15),
                                      registrationType == 'email'
                                          ? buildEmailField()
                                          : Column(
                                              children: [
                                                buildDropDownButtons(),
                                                SizedBox(
                                                    height: SizeConfig
                                                            .screenHeight *
                                                        0.02),
                                                buildPhoneNumberField(),
                                              ],
                                            ),
                                      const SizedBox(height: 20),
                                      Utils.customButton(
                                        SizeConfig.screenWidth * 0.45,
                                        AppLocalizations.of(context)
                                            .continueText,
                                        () async {
                                          if (countryCode == "OT" &&
                                              registrationType == 'phone') {
                                            Utils.showToast(
                                                context,
                                                AppLocalizations.of(context)
                                                    .emailRequired,
                                                Colors.pink);
                                          } else {
                                            if (_formkey.currentState
                                                .validate()) {
                                              setLoadingStatus(true);
                                              _formkey.currentState.save();
                                              _email =
                                                  registrationType != 'phone'
                                                      ? _email.toLowerCase()
                                                      : '';
                                              _phone = registrationType ==
                                                      'phone'
                                                  ? FormValidators.trimLeft0(
                                                      _phone)
                                                  : '';
                                              if (currentUser != null &&
                                                  (currentUser.email ==
                                                          _email ||
                                                      (currentUser.phoneNumber
                                                              .endsWith(
                                                                  _phone) &&
                                                          !currentUser
                                                              .phoneNumber
                                                              .endsWith(
                                                                  '0000000000') &&
                                                          _phone.length > 6))) {
                                                cUP.setAccountStatusActive(
                                                    isActive: true);
                                                String updatedDeviceIds =
                                                    UserModel
                                                        .getUpdatedDeviceIds(
                                                            newDeviceId,
                                                            currentUser
                                                                .deviceIds);
                                                await authService
                                                    .signInWithEmailAndPassword(
                                                        currentUser.email,
                                                        currentUser.email);
                                                currentUser.user_lang =
                                                    AppLocalizations.of(context)
                                                        .localeName;
                                                if (updatedDeviceIds !=
                                                    currentUser.deviceIds) {
                                                  currentUser.deviceIds =
                                                      updatedDeviceIds;
                                                  ApiRequest.updateUserDevices(
                                                      userId:
                                                          currentUser.user_id,
                                                      newDeviceToken:
                                                          updatedDeviceIds);
                                                  currentUser.user_lang =
                                                      AppLocalizations.of(
                                                              context)
                                                          .localeName;
                                                  await cUP
                                                      .saveUser(currentUser);
                                                }
                                                setLoadingStatus(false);
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                BottomNavController()));
                                              } else {
                                                final extractedUser = registrationType !=
                                                        'phone'
                                                    ? await ApiRequest
                                                        .isEmailOrPhoneRegistered(
                                                            email: _emailController
                                                                .text
                                                                .toLowerCase())
                                                    : await ApiRequest.isEmailOrPhoneRegistered(
                                                        internationalPhoneNumber:
                                                            _countryDialCode +
                                                                FormValidators.trimLeft0(
                                                                    _phonenumbercontroller
                                                                        .text
                                                                        .trim()));
                                                if (extractedUser != null) {
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (context) => OtpScreen(
                                                              currentUser:
                                                                  extractedUser,
                                                              canVerifyPhone:
                                                                  registrationType ==
                                                                      'phone')));
                                                } else {
                                                  if (registrationType ==
                                                      'phone') {
                                                    doesPhoneNumberExists =
                                                        AppLocalizations.of(
                                                                context)
                                                            .accountDoesNotExistsPleaseSignup;
                                                  } else {
                                                    doesEmailExist =
                                                        AppLocalizations.of(
                                                                context)
                                                            .accountDoesNotExistsPleaseSignup;
                                                    checkEmailRegistered = 'No';
                                                  }
                                                  setLoadingStatus(false);
                                                }
                                              }
                                            } else {
                                              String validationMessage =
                                                  registrationType == "email"
                                                      ? AppLocalizations.of(
                                                              context)
                                                          .emailRequired
                                                      : AppLocalizations.of(
                                                              context)
                                                          .phoneNumber;
                                              Utils.showToast(
                                                  context,
                                                  validationMessage,
                                                  Colors.red);
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                          alignment: WrapAlignment.center,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context).notHavingAccountYet} '),
                                            GestureDetector(
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .sign_up,
                                                  style: TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline),
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (_) => RegistrationScreen(
                                                              enteredCountryCode:
                                                                  countryCode,
                                                              enteredEmail:
                                                                  _emailController
                                                                      .text
                                                                      .trim(),
                                                              enteredPhone:
                                                                  _phonenumbercontroller
                                                                      .text
                                                                      .trim())));
                                                })
                                          ]),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ))));
  }

  Widget buildToggleButtons() {
    return ToggleButtons(
      children: <Widget>[
        Utils.toggleButtonChild([
          const Icon(Icons.phone),
          const Text('Phone', style: TextStyle(color: Colors.black))
        ]),
        Utils.toggleButtonChild([
          const Text('Email', style: TextStyle(color: Colors.black)),
          const Icon(Icons.email)
        ]),
      ],
      isSelected: _signInSelectedMethods,
      onPressed: (int index) {
        //String selection = index == 0 ? '\nPhone input Selected.\n' : '\nEmail input Selected.\n';
        for (int i = 0; i < _signInSelectedMethods.length; i++) {
          _signInSelectedMethods[i] = i == index;
        }
        setState(() {
          registrationType = index == 0 ? 'phone' : 'email';
        });
      },
      color: Colors.blue,
      selectedColor: Colors.blueGrey,
      fillColor: Colors.blueAccent[100],
      borderColor: Colors.blue,
      borderRadius: BorderRadius.circular(10.0),
      borderWidth: 2,
    );
  }

  Widget buildEmailField() {
    return Padding(
        padding:
            EdgeInsets.symmetric(horizontal: SizeConfig.screenWidth * 0.03),
        child: TextFormField(
          controller: _emailController,
          maxLines: 1,
          maxLength: 40,
          autovalidateMode: AutovalidateMode.always,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (email) {
            if (email == null || email.isEmpty) {
              return AppLocalizations.of(context).enterYourEmailAddress;
            } else if (!FormValidators.isAValidEmail(email)) {
              return AppLocalizations.of(context).enterAValidEmailAddress;
            } else if (doesEmailExist != null) {
              return doesEmailExist;
            }
            return null;
          },
          style: const TextStyle(color: colorBlack, fontSize: 15),
          onChanged: onChangeEmail,
          onSaved: (value) => _email = value ?? '',
        ));
  }

  Widget buildPhoneNumberField() {
    return Container(

        //color: Colors.blue,
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            _countryDialCode != null ? _countryDialCode : '    ',
            style:
                TextStyle(color: Theme.of(context).accentColor, fontSize: 16),
          ),
        ),
        SizedBox(width: SizeConfig.screenWidth * 0.03),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.screenWidth * 0.03,
                right: SizeConfig.screenWidth * 0.08),
            child: TextFormField(
              controller: _phonenumbercontroller,
              maxLines: 1,
              autofocus: false,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).phoneNumber),
              style: const TextStyle(color: colorBlack, fontSize: 15),
              validator: (phoneNumber) {
                if (phoneNumber == null || phoneNumber.isEmpty) {
                  return AppLocalizations.of(context).phoneNumber;
                } else if (_countryDialCode == null) {
                  return AppLocalizations.of(context).selectYourCountry;
                } else if (FormValidators.isValidPhoneNumber(
                        phoneNumber: phoneNumber, phoneRegex: phoneRegex) !=
                    null) {
                  return AppLocalizations.of(context).phoneNumber +
                      ' ' +
                      AppLocalizations.of(context).invalid;
                } else if (doesPhoneNumberExists != null) {
                  return doesPhoneNumberExists;
                }
                return null;
              },
              onSaved: (phone) => _phone = phone ?? "",
              onChanged: (phone) => doesPhoneNumberExists = null,
            ),
          ),
        ),
      ],
    ));
  }

  Widget buildDropDownButtons() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14.5),
        decoration: Utils.containerBoxDecoration(
            radius: 20, borderColor: Colors.blue, borderWidth: 2),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context).selectYourCountry),
              isDense: true,
              isExpanded: true,
              value: countryCode,
              onChanged: (country) {
                Map<dynamic, dynamic> chooseCountry =
                    Constants.countryLookupMap[country];
                String dailCode = chooseCountry['dial_code'];
                setState(() {
                  countryCode = country;
                  phoneRegex = chooseCountry['mobile_phone_regex_pattern'];
                  _countryDialCode = dailCode;
                });
                if (country == "OT" && registrationType != 'email') {
                  Utils.showToast(context,
                      AppLocalizations.of(context).emailRequired, Colors.pink);
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (country) {
                return country == null
                    ? AppLocalizations.of(context).selectYourCountry
                    : country == "OT" && registrationType == 'phone'
                        ? AppLocalizations.of(context).emailRequired
                        : null;
              },
              items: Constants.countryLookupMap.entries.map((kvpair) {
                return DropdownMenuItem<String>(
                  value: kvpair.key,
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        kvpair.value["flag"],
                        width: 25,
                      ),
                      kvpair.value["country_name"] != "Other"
                          ? Text(kvpair.value["dial_code"])
                          : Text(kvpair.value["dial_code"],
                              style: const TextStyle(color: Colors.red)),
                      Container(
                          margin: const EdgeInsets.only(left: 10),
                          child: kvpair.value["country_name"] == "Other"
                              ? Text(
                                  AppLocalizations.of(context).other,
                                  style: const TextStyle(color: Colors.red),
                                )
                              : Text(kvpair.value["country_name"]))
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ));
  }

  onChangeEmail(String email) {
    doesEmailExist = null;
    checkEmailRegistered = null;
    if (email != null && email.isNotEmpty) {
      if (FormValidators.isAValidEmail(email.trim())) {
        checkEmailRegistered = null;
      }
    }
    setState(() {});
  }
}
