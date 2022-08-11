import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peervendors/HomeScreen/Nav_Bar_Pages/view_profile.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/form_validators.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/get_images.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfile extends StatefulWidget {
  UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  bool intendToAddPhone;

  EditProfile(
      {Key key,
      @required this.currentUser,
      @required this.cUP,
      @required this.intendToAddPhone})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MyEditProfile();
  }
}

class MyEditProfile extends State<EditProfile> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];
  final _profileDescController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPhoneNumber = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _newEmailNumber = TextEditingController();
  String localProfile;
  List<String> otpCodes = [];

  String _profileText = '', _email = '', flag = '';
  Map<String, dynamic> country = {};
  Map<String, dynamic> countryInfo = {};
  Map<String, String> reverificationParams = {};

  bool currentState = false;
  bool shouldShowOtpBox = false;
  bool isEmailReadOnly = false;
  bool isPhoneReadOnly = false;

  //firebase phone verification
  AuthService authService = AuthService();
  String firebaseVerificationId;
  bool useFirebasePhone = false;
  bool showTooManyAttempts = false;
  int firebaseResendToken;
  int lastTimeVerifcationCodeWasSent;
  String verificationMessage = '';
  String verificationId;
  String newNumberPhoneNumber = '';
  String newEmail = '';
  int forceResendingToken;
  bool isVerifyingPhone = false;
  bool needsToEnterNewPhone = false;
  bool hasNotVerifiedPhone = true;

  bool isVerifyingEmail = false;
  bool needsToEnterNewEmail = false;
  bool hasNotVerifiedEmail = true;

  String isEmailTaken;
  String isPhoneTaken;
  final ImagePicker _imagePicker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    needsToEnterNewPhone = widget.intendToAddPhone;
    setUserPrefs();
    super.initState();
  }

  @override
  void dispose() {
    _profileDescController.dispose();
    _phoneController.dispose();
    _newPhoneNumber.dispose();
    _emailController.dispose();
    _newEmailNumber.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future setUserPrefs() async {
    countryInfo = Constants.countryLookupMap[widget.currentUser.country_code];
    reverificationParams = {
      'userName': widget.currentUser.username,
      'internationalPhoneNumber': widget.currentUser.phoneNumber,
      'user_id': widget.currentUser.user_id.toString(),
      'email': widget.currentUser.email,
      'isConfirmation': 'no',
      'lang': widget.currentUser.user_lang,
      'firebase_id': widget.currentUser.firebaseUserId
    };

    country =
        Constants.getCountryInfo(countryCode: widget.currentUser.country_code);
    setState(() {
      flag = country['flag'];
      _email = widget.currentUser.email.split('-').length == 5
          ? 'no@email.proprovided'
          : widget.currentUser.email;
      _emailController.text = widget.currentUser.email.split('-').length == 5
          ? 'no@email.provided'
          : widget.currentUser.email;
      _phoneController.text = widget
          .currentUser.phoneNumber; //.replaceAll(country['dial_code'], '');
    });
    ApiRequest.getUserInfo(widget.currentUser.user_id, addReviews: 1)
        .then((profile) {
      String profileMessage = profile.customer_info.profile_message;
      String t = profileMessage == null || profileMessage.length < 10
          ? AppLocalizations.of(context).saySomethingAboutYourself
          : profileMessage;
      setState(() {
        _profileText = t;
        _profileDescController.text = t;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double defaultItemsSep = 10;
    if (!reverificationParams.containsKey('lang')) {
      reverificationParams['lang'] = AppLocalizations.of(context).localeName;
    }
    return SafeArea(
        child: Scaffold(
      backgroundColor: colorWhite,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Colors.blueAccent[400],
        title: Text(AppLocalizations.of(context).editProfile),
        elevation: 2,
      ),
      body: !isLoading
          ? SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(children: [
                Stack(children: [
                  Utils.buildStack(
                      SizeConfig.screenWidth,
                      SizeConfig.screenHeight,
                      localProfile == null
                          ? '${Constants.profileImagesBaseUrl}${widget.currentUser.profilePicture}'
                          : localProfile),
                  Positioned(
                    top: SizeConfig.screenHeight * 0.115,
                    right: SizeConfig.screenWidth * 0.20,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorGrey300,
                      child: IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.edit),
                        color: colorGrey700,
                        onPressed: showImagePicker,
                      ),
                    ),
                  )
                ]),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.currentUser.username,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: defaultItemsSep),
                          SizedBox(
                            height: 18,
                            child: Image.asset(flag),
                            width: 25,
                          ),
                        ],
                      ),
                      SizedBox(height: defaultItemsSep / 2),
                      Utils.buildText(
                          AppLocalizations.of(context)
                              .saySomethingAboutYourself,
                          color: colorGrey700,
                          fontSize: 12),
                      buildEditableText(
                          context, _profileText, showInformationDialog),
                      SizedBox(height: defaultItemsSep / 2),
                      Utils.buildText(AppLocalizations.of(context).phoneNumber,
                          color: colorGrey700, fontSize: 12),
                      Utils.buildText(
                          AppLocalizations.of(context).numberForBuyersContact,
                          color: colorGrey700,
                          fontSize: 12),
                      buildEditableText(context, _phoneController.text,
                          () async {
                        setState(() {
                          needsToEnterNewPhone = true;
                        });
                      }),
                      // ElevatedButton(
                      //     child: Text('Test'),
                      //     onPressed: () async {
                      //       print(widget.currentUser.profilePicture);
                      //     }),
                      // ElevatedButton(
                      //     child: Text('Verify'),
                      //     onPressed: () async {
                      //       print(authService.authInstance.currentUser);
                      //     }),
                      needsToEnterNewPhone && hasNotVerifiedPhone
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: defaultItemsSep),
                              child: Text(AppLocalizations.of(context)
                                  .enterNewPhoneNumber),
                            )
                          : const SizedBox.shrink(),
                      needsToEnterNewPhone && hasNotVerifiedPhone
                          ? TextFormField(
                              readOnly: isPhoneReadOnly,
                              controller: _newPhoneNumber,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  isDense: true,
                                  prefixIcon: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Text(countryInfo["dial_code"])),
                                  prefixIconConstraints:
                                      BoxConstraints(minWidth: 0, minHeight: 0),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Container(
                                      height: 40,
                                      width: 42,
                                      decoration: Utils.containerBoxDecoration(
                                          color: Colors.blue[400]),
                                      child: IconButton(
                                          hoverColor: Colors.red,
                                          icon: const Icon(
                                            FontAwesomeIcons.paperPlane,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async {
                                            String localNumb =
                                                _newPhoneNumber.text.trim();
                                            String isValidPhone = FormValidators
                                                .isValidPhoneNumber(
                                                    phoneNumber: localNumb,
                                                    phoneRegex: countryInfo[
                                                        'mobile_phone_regex_pattern']);
                                            if (isValidPhone == null) {
                                              setState(() {
                                                currentState = true;
                                              });
                                              var phoneNumber =
                                                  countryInfo["dial_code"] +
                                                      FormValidators.trimLeft0(
                                                          localNumb);

                                              if (phoneNumber !=
                                                  widget.currentUser
                                                      .phoneNumber) {
                                                var t = await ApiRequest
                                                    .isEmailOrPhoneRegistered(
                                                        internationalPhoneNumber:
                                                            phoneNumber);
                                                if (t == null) {
                                                  verifyPhoneNumber(
                                                      widget.currentUser,
                                                      null,
                                                      phoneNumber,
                                                      context);
                                                  isVerifyingPhone = true;
                                                } else {
                                                  setState(() {
                                                    isPhoneTaken =
                                                        AppLocalizations.of(
                                                                    context)
                                                                .phoneNumber +
                                                            ' ' +
                                                            AppLocalizations.of(
                                                                    context)
                                                                .alreadyExists;
                                                  });
                                                }
                                              } else {
                                                setState(() {
                                                  isPhoneTaken =
                                                      AppLocalizations.of(
                                                                  context)
                                                              .phoneNumber +
                                                          ' ' +
                                                          AppLocalizations.of(
                                                                  context)
                                                              .alreadyExists;
                                                });
                                              }
                                              setState(() {
                                                currentState = false;
                                              });
                                            }
                                          }),
                                    ),
                                  )),
                              autovalidateMode: AutovalidateMode.always,
                              onChanged: (newValue) {
                                if (isPhoneTaken != null) {
                                  setState(() {
                                    isPhoneTaken = null;
                                  });
                                }
                              },
                              validator: (value) {
                                if (isPhoneTaken != null) {
                                  return isPhoneTaken;
                                }
                                String isValidPhone =
                                    FormValidators.isValidPhoneNumber(
                                        phoneNumber: value,
                                        phoneRegex: countryInfo[
                                            'mobile_phone_regex_pattern']);

                                return isValidPhone == null
                                    ? null
                                    : AppLocalizations.of(context).invalid +
                                        ' ' +
                                        AppLocalizations.of(context)
                                            .phoneNumber;
                              },
                            )
                          : const SizedBox.shrink(),
                      isVerifyingPhone && hasNotVerifiedPhone
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: defaultItemsSep),
                              child: Text(AppLocalizations.of(context)
                                  .enterVerificationCode))
                          : const SizedBox.shrink(),
                      isVerifyingPhone && hasNotVerifiedPhone
                          ? TextFormField(
                              maxLength: 6,
                              controller: _otpController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                isDense: true,
                              ),
                              autovalidateMode: AutovalidateMode.always,
                              onChanged: (otp) async {
                                if (otp?.trim()?.length == 6) {
                                  if (useFirebasePhone) {
                                    UserCredential userCreds;
                                    try {
                                      PhoneAuthCredential credential =
                                          PhoneAuthProvider.credential(
                                              verificationId: verificationId,
                                              smsCode: otp);
                                      if (authService
                                              .authInstance.currentUser ==
                                          null) {
                                        final newCreds = await authService
                                            .authInstance
                                            .signInWithEmailAndPassword(
                                                email: widget.currentUser.email,
                                                password: authService.pASSWORD);

                                        if (newCreds?.user != null) {
                                          newCreds.user
                                              .updatePhoneNumber(credential);
                                          userCreds = newCreds;
                                        } else {}
                                      } else {
                                        await authService
                                            .authInstance.currentUser
                                            .updatePhoneNumber(credential);
                                      }
                                      currentState = false;
                                      _otpController.text = '';
                                      shouldShowOtpBox = false;
                                      widget.currentUser.phoneNumber =
                                          newNumberPhoneNumber;
                                      needsToEnterNewPhone = false;
                                      isVerifyingPhone = false;
                                      hasNotVerifiedPhone = false;
                                      reverificationParams['isConfirmation'] =
                                          'yes';

                                      reverificationParams[
                                              'reverificationType'] =
                                          'phone_number';
                                      reverificationParams['isConfirmation'] =
                                          'yes';
                                      reverificationParams[
                                              'internationalPhoneNumber'] =
                                          newNumberPhoneNumber;
                                      reverificationParams['email '] =
                                          widget.currentUser.email;
                                      final result = await ApiRequest
                                          .sendReverificationCode(
                                              params: reverificationParams);
                                      if (result != null) {
                                        _phoneController.text =
                                            newNumberPhoneNumber;
                                        widget.currentUser.phoneNumber =
                                            newNumberPhoneNumber;
                                        widget.currentUser.user_lang =
                                            AppLocalizations.of(context)
                                                .localeName;
                                        widget.cUP.saveUser(widget.currentUser);

                                        setState(() {});
                                        Utils.showToast(
                                            context,
                                            AppLocalizations.of(context)
                                                .authenticationSuccessful,
                                            Colors.green);
                                      }
                                      widget.currentUser.phoneNumber =
                                          newNumberPhoneNumber;
                                      widget.cUP.saveUser(widget.currentUser);
                                    } on FirebaseAuthException catch (e) {
                                      final errorCode = e.code;
                                      var t = widget.currentUser;
                                      if ([
                                            'provider-already-linked',
                                            'credential-already-in-use'
                                          ].contains(errorCode) &&
                                          userCreds?.user != null) {
                                        final User user = userCreds.user;
                                        if (user.uid ==
                                                widget.currentUser
                                                    .firebaseUserId &&
                                            user.phoneNumber.endsWith(widget
                                                .currentUser.phoneNumber
                                                .substring(4))) {
                                          Utils.showToast(
                                              context,
                                              AppLocalizations.of(context)
                                                  .authenticationSuccessful,
                                              Colors.green);
                                        }
                                      } else if ([
                                        'invalid-credential',
                                        'invalid-verification-code',
                                        'invalid-verification-id'
                                      ].contains(errorCode)) {
                                        Utils.showToast(
                                            context,
                                            AppLocalizations.of(context)
                                                .invalidOtpCode,
                                            Colors.pink);
                                      } else {
                                        ApiRequest.reportVerificationError(
                                            params: {
                                              'userId': '${t.user_id}',
                                              'email': t.email,
                                              'phoneNumber': t.phoneNumber,
                                              'countryCode': t.country_code,
                                              'languageCode': t.user_lang,
                                              'vCode': t.last_verification_code,
                                              'DeviceIds': t.deviceIds,
                                              'errorCode': errorCode
                                            });
                                        Utils.showToast(
                                            context,
                                            AppLocalizations.of(context)
                                                .loginFailed,
                                            Colors.pink);
                                      }
                                    }
                                  }
                                }
                              },
                              validator: (otp) {
                                return validateOtp(otp);
                              },
                            )
                          : const SizedBox.shrink(),
                      SizedBox(height: defaultItemsSep / 2),
                      Utils.buildText(AppLocalizations.of(context).email,
                          color: colorGrey700, fontSize: 12),
                      buildEditableText(
                          context,
                          widget.currentUser.email.split('-').length == 5
                              ? 'no@email.provided'
                              : widget.currentUser.email, () async {
                        setState(() {
                          needsToEnterNewEmail = true;
                          _emailController.text = '';
                        });
                      }),
                      SizedBox(height: defaultItemsSep / 2),
                      needsToEnterNewEmail && hasNotVerifiedEmail
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: defaultItemsSep),
                              child: Text(
                                  AppLocalizations.of(context).enterNewEmail),
                            )
                          : const SizedBox.shrink(),
                      needsToEnterNewEmail && hasNotVerifiedEmail
                          ? TextFormField(
                              readOnly: isEmailReadOnly,
                              controller: _emailController,
                              textCapitalization: TextCapitalization.none,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  isDense: true,
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Container(
                                      height: 40,
                                      width: 42,
                                      decoration: Utils.containerBoxDecoration(
                                          color: Colors.blue[400]),
                                      child: IconButton(
                                          hoverColor: Colors.red,
                                          icon: const Icon(
                                            FontAwesomeIcons.paperPlane,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async {
                                            String email =
                                                _emailController.text.trim();
                                            bool isValidPhone =
                                                FormValidators.isAValidEmail(
                                                    email);
                                            if (isValidPhone) {
                                              setState(() {
                                                currentState = true;
                                              });
                                              var t = await ApiRequest
                                                  .isEmailOrPhoneRegistered(
                                                      email: email);
                                              if (t == null) {
                                                var rng = new Random();
                                                int code = rng.nextInt(900000) +
                                                    100000;
                                                var p = await ApiRequest
                                                    .sendEmailToUsers(params: {
                                                  "userName": widget
                                                      .currentUser.username,
                                                  "user_id": widget
                                                      .currentUser.user_id
                                                      .toString(),
                                                  'email_list': email,
                                                  "email_message_body":
                                                      "Hello ${widget.currentUser.username}, $code is Your Peer Vendors Verification Code.",
                                                  'email_title':
                                                      "Peer Vendors Verification Code"
                                                });
                                                if (p != null &&
                                                    p['status'] == 'success') {
                                                  otpCodes.add(code.toString());
                                                  newEmail = email;
                                                  isVerifyingEmail = true;
                                                  isEmailReadOnly = true;
                                                  hasNotVerifiedEmail = true;
                                                  setState(() {});
                                                }
                                              } else {
                                                isEmailTaken =
                                                    AppLocalizations.of(context)
                                                            .email +
                                                        ' ' +
                                                        AppLocalizations.of(
                                                                context)
                                                            .alreadyExists;
                                                setState(() {});
                                              }
                                              setState(() {
                                                currentState = false;
                                              });
                                            } else {
                                              setState(() {
                                                isEmailTaken =
                                                    AppLocalizations.of(context)
                                                            .email +
                                                        ' ' +
                                                        AppLocalizations.of(
                                                                context)
                                                            .alreadyExists;
                                              });
                                            }
                                            setState(() {
                                              currentState = false;
                                            });
                                          }),
                                    ),
                                  )),
                              autovalidateMode: AutovalidateMode.always,
                              onChanged: (newValue) {
                                // print(widget.currentUser.email);
                                // var s = widget.cUP.getCurrentUser();
                                // print(s.email);
                                if (isEmailTaken != null) {
                                  setState(() {
                                    isEmailTaken = null;
                                  });
                                }
                              },
                              validator: (value) {
                                bool isValidEmail =
                                    FormValidators.isAValidEmail(value.trim());
                                if (isEmailTaken != null) {
                                  return isEmailTaken;
                                }
                                return isValidEmail
                                    ? null
                                    : AppLocalizations.of(context).invalid +
                                        ' ' +
                                        AppLocalizations.of(context).email;
                              },
                            )
                          : const SizedBox.shrink(),
                      isVerifyingEmail && hasNotVerifiedEmail
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: defaultItemsSep),
                              child: Text(AppLocalizations.of(context)
                                  .enterVerificationCode))
                          : const SizedBox.shrink(),
                      isVerifyingEmail && hasNotVerifiedEmail
                          ? TextFormField(
                              maxLength: 6,
                              controller: _newEmailNumber,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                isDense: true,
                              ),
                              autovalidateMode: AutovalidateMode.always,
                              onChanged: (otp) async {
                                if (otp?.trim()?.length == 6) {
                                  bool isValid = otpCodes.contains(otp);
                                  if (isValid) {
                                    reverificationParams['isConfirmation'] =
                                        'yes';
                                    reverificationParams['reverificationType'] =
                                        'email';
                                    reverificationParams['email'] = newEmail;
                                    final result =
                                        await ApiRequest.sendReverificationCode(
                                            params: reverificationParams);
                                    if (result != null) {
                                      widget.currentUser.email = newEmail;

                                      widget.currentUser.user_lang =
                                          AppLocalizations.of(context)
                                              .localeName;
                                      widget.cUP.saveUser(widget.currentUser);
                                      otpCodes.remove(otp);
                                      _newEmailNumber.text = '';
                                      shouldShowOtpBox = false;
                                      needsToEnterNewEmail = false;
                                      hasNotVerifiedEmail = false;
                                      isEmailReadOnly = true;
                                      setState(() {});
                                      Utils.showToast(
                                          context,
                                          AppLocalizations.of(context)
                                              .authenticationSuccessful,
                                          Colors.green);
                                    }
                                  }
                                }
                              },
                              validator: (otp) {
                                return validateOtp(otp);
                              },
                            )
                          : const SizedBox.shrink(),
                      SizedBox(height: defaultItemsSep / 2),
                      Center(
                          child: SizedBox(
                              height: 35,
                              width: 200,
                              child: ElevatedButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => UserProfilePage(
                                              currentUser: widget.currentUser,
                                              isEditable: true,
                                              cUP: widget.cUP))),
                                  style: Utils.roundedButtonStyle(radius: 5),
                                  child: Text(
                                    AppLocalizations.of(context).accountMetrics,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  )))),
                      Container(height: 200)
                    ],
                  ),
                )
              ]),
            )
          : Utils.loadingWidget(AppLocalizations.of(context).savingImage),
      //bottomNavigationBar: Utils.buildBottomBar(color: Colors.blue)
    ));
  }

  Widget buildEditableText(
      BuildContext context, String text, Function() onPressedFunct) {
    return Column(children: [
      Row(
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
          IconButton(
            icon: Container(
                decoration: Utils.containerBoxDecoration(
                    borderColor: Colors.blue[700], borderWidth: 3, radius: 5),
                child: const Icon(Icons.edit, size: 16, color: colorGrey700)),
            onPressed: () async {
              await onPressedFunct();
              setState(() {});
            },
          ),
        ],
      ),
    ]);
  }

  Future resendFirebaseCode(int resendToken, UserModel user,
      String internationalPhone, BuildContext context) async {
    await verifyPhoneNumber(user, resendToken, internationalPhone, context);
  }

  Future completeVerification(PhoneAuthCredential credential, UserModel user,
      String newPhoneNumber) async {
    try {
      final cred = await authService.signInWithEmailAndPasswordToLinkAccount(
          user.email, user.email);
      await cred.user.linkWithCredential(credential);
    } catch (e) {}

    needsToEnterNewPhone = false;
    isVerifyingPhone = false;
    hasNotVerifiedPhone = false;

    reverificationParams['reverificationType'] = 'phone_number';
    reverificationParams['isConfirmation'] = 'yes';
    reverificationParams['internationalPhoneNumber'] = newPhoneNumber;
    reverificationParams['email '] = user.email;

    final result =
        await ApiRequest.sendReverificationCode(params: reverificationParams);
    if (result != null) {
      _phoneController.text = newPhoneNumber;
      widget.currentUser.phoneNumber = newPhoneNumber;

      widget.currentUser.user_lang = AppLocalizations.of(context).localeName;
      widget.cUP.saveUser(widget.currentUser);
      currentState = false;
      _otpController.text = '';
      shouldShowOtpBox = false;
      setState(() {});
      Utils.showToast(context,
          AppLocalizations.of(context).authenticationSuccessful, Colors.green);
    }
    user.phoneNumber = newPhoneNumber;
    widget.cUP.saveUser(user);
  }

  Future verifyPhoneNumber(UserModel user, int resendingToken,
      String phoneNumber, BuildContext context) async {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (authService.authInstance.currentUser == null) {
      await authService.signInWithEmailAndPassword(user.email, user.email);
    }
    await authService.authInstance.verifyPhoneNumber(
      forceResendingToken: resendingToken,
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 118),
      verificationCompleted: (PhoneAuthCredential credential) async {
        completeVerification(credential, widget.currentUser, phoneNumber);
      },
      verificationFailed: (FirebaseAuthException e) async {
        final errorCode = e.code;
        if (errorCode == 'too-many-requests') {
          Utils.showToast(
              context, AppLocalizations.of(context).tooManyFailures, Colors.red,
              duration: 6);
          useFirebasePhone = false;
          showTooManyAttempts = true;
        } else if (!['invalid-phone-number', 'unknown'].contains(errorCode)) {
          Map<String, String> params = {
            'internationalPhoneNumber': phoneNumber,
            'userName': user.email,
            'email': user.email,
            'user_id': '${user.user_id}',
            'reverificationType': 'phone_number',
            'isConfirmation': 'no',
            'lang': user.user_lang,
            'firebase_id': user.firebaseUserId,
            'errorCode': errorCode,
            'code': '${user.last_verification_code}'
          };
          final result =
              await ApiRequest.sendReverificationCode(params: params);

          var code = result == null ? "" : "${result['OTPCode']}";
          verifyCode(code, context, AppLocalizations.of(context).phoneNumber);
        } else {
          ApiRequest.notifyInvalidPhone(params: {
            'user_id': '${user.user_id}',
            'phone_number': user.phoneNumber,
            'email': user.email,
            'device_ids': user.deviceIds,
            'username': user.username,
            'lang': user.user_lang
          });
        }
      },
      codeSent: (verifId, newResendingToken) async {
        newNumberPhoneNumber = phoneNumber;
        codeSentToUser(verifId, newResendingToken, user);
      },
      codeAutoRetrievalTimeout: (verifId) async {
        verificationId = verifId;
        useFirebasePhone = false;
        if (hasNotVerifiedPhone) {
          resendFirebaseCode(forceResendingToken, user, phoneNumber, context);
        }
      },
    );
  }

  Future verifyCode(String code, BuildContext context, String vType) async {
    if (code.length == 6) {
      otpCodes.add(code);
      await Future.wait([
        widget.cUP
            .saveString(Constants.peerVendorsLastVCodes, otpCodes.join(',')),
        widget.cUP.setTimeWhenEventHappened(
            eventName: Constants.whenLastVerificationCodeWasSent)
      ]);
      Utils.showToast(context, AppLocalizations.of(context).newVerificationCode,
          Colors.green);
    } else {
      Utils.showToast(
          context,
          AppLocalizations.of(context).loginFailed + ' invalid $vType Error',
          Colors.red);
    }
  }

  Future codeSentToUser(
      String verifId, int newResendingToken, UserModel user) async {
    setState(() {
      verificationId = verifId;
      forceResendingToken = newResendingToken;
      useFirebasePhone = true;
      isPhoneTaken = null;
      isPhoneReadOnly = true;
      shouldShowOtpBox = true;
      isVerifyingPhone = true;
      needsToEnterNewPhone = true;
    });
  }

  String validateOtp(String otp) {
    if (otp?.length == 6) {
      return otpCodes.contains(otp)
          ? null
          : AppLocalizations.of(context).invalidOtpCode;
    }
    return AppLocalizations.of(context).invalidOtpCode;
  }

  Future<void> showInformationDialog() async {
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 5),
              title:
                  Text(AppLocalizations.of(context).saySomethingAboutYourself),
              content: Form(
                  key: _formKeys[0],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        maxLength: 140,
                        maxLines: 4,
                        minLines: 1,
                        autovalidateMode: AutovalidateMode.always,
                        controller: _profileDescController,
                        onChanged: (email) {
                          _email = email;
                        },
                        validator: (value) {
                          return value.isNotEmpty && value.length > 10
                              ? null
                              : AppLocalizations.of(context).invalid;
                        },
                        decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                .saySomethingAboutYourself),
                      )
                    ],
                  )),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context).save),
                  onPressed: () async {
                    if (_formKeys[0].currentState.validate()) {
                      if (_profileDescController.text != _profileText) {
                        Map<String, String> params = {
                          'string_field_value': _profileDescController.text,
                          'user_id': widget.currentUser.user_id.toString(),
                          'profile_field': 'profile_message'
                        };
                        ApiRequest.updateProfileField(params: params);
                        setState(() {
                          _profileText = _profileDescController.text;
                        });
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  Future chooseProfileImage(ImageSource source) async {
    PermissionStatus status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.storage.request();
    if (status == PermissionStatus.granted) {
      List<dynamic> pickedFileDetails = await GetImages.getImageFile(
          _imagePicker, source,
          imageUseFor: "profile");
      if (pickedFileDetails != null && pickedFileDetails[1] != null) {
        setState(() {
          isLoading = true;
        });
        String fn = widget.currentUser.profilePicture !=
                    'default_profile_picture.jpg' &&
                widget.currentUser.profilePicture != null
            ? widget.currentUser.profilePicture.split('.').first
            : pickedFileDetails[1];
        String returned = await ApiRequest.postAnImage(
            imageFilePath: pickedFileDetails[0].path,
            imageType: 'profile',
            fileName: fn);
        if (returned != null) {
          Map<String, String> params = {
            'profile_picture': returned,
            'user_id': widget.currentUser.user_id.toString()
          };
          ApiRequest.updateProfile(params: params).then((map) {
            if (map != null && map['was_update_successful']) {
              localProfile = pickedFileDetails[0].path;
              widget.currentUser.profilePicture = map['profile_picture'];
              widget.cUP.saveUser(widget.currentUser);
              setState(() {});
            }
          });
        } else {
          Utils.showToast(
              context, AppLocalizations.of(context).uploadFailed, Colors.red);
        }
        setState(() {
          isLoading = false;
        });
      }
      //prepareData();
    }
  }

  showImagePicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black45,
          height: SizeConfig.screenHeight / 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    child: ListTile(
                      title: const Text("Camera"),
                      leading: const Icon(Icons.camera),
                      onTap: () {
                        Navigator.of(context).pop();
                        chooseProfileImage(ImageSource.camera);
                      },
                    ),
                    elevation: 6,
                  ),
                  Card(
                    child: ListTile(
                      title: const Text("Gallery"),
                      leading: const Icon(Icons.photo_library),
                      onTap: () {
                        Navigator.of(context).pop();
                        chooseProfileImage(ImageSource.gallery);
                      },
                    ),
                    elevation: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
