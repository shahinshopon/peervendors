import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:peervendors/helpers/default_addresses.dart';
import 'package:peervendors/helpers/form_validators.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/addresses.dart';

import '../success_screen.dart';

//Dealing with dropdown flags https://www.youtube.com/watch?v=-6GBAGj-h4Q
//searchable Dropdown with select https://www.youtube.com/watch?v=L3E4LNSrSWM
//
//Dropdown list with images and source code https://github.com/khaliqdadmohmand/flutter_dropdownListWithImages

class OtpScreen extends StatefulWidget {
  final UserModel currentUser;
  final bool canVerifyPhone;

  @override
  _OtpScreenState createState() => _OtpScreenState();
  OtpScreen(
      {Key key, @required this.currentUser, @required this.canVerifyPhone})
      : super(key: key);
}

class _OtpScreenState extends State<OtpScreen> {
  final _formkey = GlobalKey<FormState>();
  String _otp;
  final _otpController = TextEditingController();
  UserPreferences cUP = UserPreferences();
  AuthService authService = AuthService();
  String firebaseVerificationId;
  bool useFirebasePhone = false;
  int firebaseResendToken;
  int lastTimeVerifcationCodeWasSent;
  String otpCodes = '';
  String verificationMessage = '';
  String verificationId;
  int forceResendingToken;
  String verificationType;
  bool isLoading = true;
  bool showTooManyAttempts = false;
  bool canSendEmail = true;
  final FirebaseAuth authInstance = FirebaseAuth.instance;
  String newDeviceId;
  bool canSendOtp = true;

  @override
  void initState() {
    verificationType = widget.canVerifyPhone &&
            ('-'.allMatches(widget.currentUser.email).length == 4 ||
                Utils.isNumeric(widget.currentUser.email.split('@').first))
        ? 'phone'
        : '${widget.currentUser.phoneNumber}'.endsWith('0000000000')
            ? 'email'
            : 'email&phone';
    super.initState();
    setUserPrefs();
    startTimer();
  }

  Timer _timer;
  int _start = 300;
  String _minsSecsTime;

  void startTimer() {
    otpCodes += ',${widget.currentUser.last_verification_code}';
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
            _minsSecsTime =
                '0${_start ~/ 60}: ${Utils.getSecondsLeft(_start % 60)}';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future getAndSaveAddress() async {
    Map<String, dynamic> savedAddress = cUP.getCurrentUserAddress();
    Map<String, dynamic> defaultAddress = DefaultAddresses.getDefaultAddres(
        countryCode: widget.currentUser.country_code);
    if (savedAddress == null ||
        savedAddress.isEmpty ||
        (widget.currentUser.country_code != 'OT' &&
            defaultAddress['address_id'] == savedAddress['address_id'])) {
      Map<String, dynamic> userAddress =
          await Addresses.getAddressFromBackend();
      if (userAddress != null) {
        cUP.saveString(
            Constants.peerVendorsCurrentAddress, json.encode(userAddress));
        cUP.setTimeWhenEventHappened(
            eventName: Constants.whenAddresLastRequested);
      }
    }
  }

  activateAccountAndSignInUser({BuildContext context, UserModel user}) async {
    ApiRequest.activateUserAccount(user.user_id);

    user.user_lang = AppLocalizations.of(context).localeName;
    await cUP.saveString(Constants.peerVendorsUser, json.encode(user));
    await cUP.setBool(key: Constants.peerVendorsAccountStatus, value: true);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SuccessScreen()));
  }

  Future<bool> authenticateUserViaFirebase({String userEmail}) async {
    String authenticatedUser = await authService.signInWithEmailAndPassword(
        userEmail.toLowerCase(), userEmail.toLowerCase());
    return authenticatedUser != null;
  }

  Future loginUser(UserModel user, BuildContext context,
      {bool verifyFirebase = true}) async {
    setState(() {
      canSendOtp = false;
    });
    if (verifyFirebase) {
      await authenticateUserViaFirebase(userEmail: user.email);
    }
    activateAccountAndSignInUser(context: context, user: user);
  }

  Future resendFirebaseCode(int resendToken, UserModel user) async {
    await verifyPhoneNumber(user, resendToken);
  }

  Future verifyPhoneNumber(UserModel user, int resendingToken) async {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (authService.authInstance.currentUser != null) {
      await authService.signOut();
    }
    if (verificationType.contains('email') &&
        (otpCodes.length <= 16 || otpCodes.split(',').toSet().length < 4)) {
      Map<String, String> params = {
        'internationalPhoneNumber': user.phoneNumber,
        'userName': user.email,
        'email': user.email,
        'user_id': '${user.user_id}',
        'reverificationType': 'email',
        'isConfirmation': 'no',
        'lang': user.user_lang,
        'firebase_id': user.firebaseUserId,
        'errorCode': 'emailVerification',
        'code': '${user.last_verification_code}'
      };
      final result = await ApiRequest.sendReverificationCode(params: params);
      final code = result == null ? "" : '${result['OTPCode']}';

      verifyCode(code, context, AppLocalizations.of(context).email);
    }

    if (verificationType.contains('phone') && widget.canVerifyPhone) {
      await authInstance.verifyPhoneNumber(
        forceResendingToken: resendingToken,
        phoneNumber: user.phoneNumber,
        timeout: const Duration(seconds: 118),
        verificationCompleted: (PhoneAuthCredential credential) async {
          loginUser(user, context);
        },
        verificationFailed: (FirebaseAuthException e) async {
          final errorCode = e.code;
          // print('Error "$errorCode"');
          // print('Error verification');
          if (errorCode == 'too-many-requests') {
            Utils.showToast(context,
                AppLocalizations.of(context).tooManyFailures, Colors.red,
                duration: 6);
            useFirebasePhone = false;
            showTooManyAttempts = true;
          } else if (!['invalid-phone-number', 'unknown'].contains(errorCode)) {
            Map<String, String> params = {
              'internationalPhoneNumber': user.phoneNumber,
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
            loginUser(user, context);
          }
        },
        codeSent: (verifId, newResendingToken) async {
          //print('Code Sent to user');
          codeSentToUser(verifId, newResendingToken, user);
        },
        codeAutoRetrievalTimeout: (verifId) async {
          verificationId = verifId;
          useFirebasePhone = false;
          if (canSendOtp && mounted) {
            resendFirebaseCode(forceResendingToken, user);
          }
        },
      );
    }
  }

  Future verifyCode(String code, BuildContext context, String vType) async {
    if (code.length == 6) {
      canSendEmail = false;
      otpCodes += ',$code';
      _start = 300;
      _timer?.cancel();
      startTimer();
      await Future.wait([
        cUP.saveString(Constants.peerVendorsLastVCodes, otpCodes),
        cUP.setTimeWhenEventHappened(
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
    verificationId = verifId;
    forceResendingToken = newResendingToken;
    useFirebasePhone = true;
  }

  Future setUserPrefs() async {
    await cUP.setUserPreferences();
    lastTimeVerifcationCodeWasSent = cUP.getTimeWhenEventHppened(
        eventName: Constants.whenLastVerificationCodeWasSent);
    getAndSaveAddress();
    try {
      String token = await FirebaseMessaging.instance.getToken();

      String updatedDeviceIds =
          UserModel.getUpdatedDeviceIds(token, widget.currentUser.deviceIds);
      if (updatedDeviceIds != widget.currentUser.deviceIds) {
        ApiRequest.updateUserDevices(
            userId: widget.currentUser.user_id,
            newDeviceToken: updatedDeviceIds);
        widget.currentUser.deviceIds = updatedDeviceIds;
        await cUP.saveUser(widget.currentUser);
      }
    } catch (e) {
      //print('Exeption e ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('verofocatopm tu[e $verificationType');
    if (verificationMessage == '') {
      verificationMessage = AppLocalizations.of(context).beInGoodNetwork +
          ' ' +
          AppLocalizations.of(context).weSentA6DigitCode;
      verificationMessage = !widget.canVerifyPhone
          ? '$verificationMessage ${widget.currentUser.email} ${AppLocalizations.of(context).refreshYourMailBox}'
          //? '$verificationMessage ${widget.currentUser.phoneNumber}.'
          : verificationType == 'phone'
              ? '$verificationMessage ${widget.currentUser.phoneNumber}.'
              : '$verificationMessage (${widget.currentUser.phoneNumber}, ${widget.currentUser.email}) ${AppLocalizations.of(context).refreshYourMailBox}';
      verifyPhoneNumber(widget.currentUser, null);
    }
    if (isLoading) {
      return Utils.loadingWidget(
          AppLocalizations.of(context).loadingPleaseWait);
    }
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            height:
                SizeConfig.screenHeight > 570 ? 570 : SizeConfig.screenHeight,
            width: SizeConfig.screenWidth,
            child: Card(
                elevation: 5,
                color: Colors.white,
                margin:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: SizeConfig.screenWidth * 0.08,
                            ),
                            onPressed: () {
                              if (_start > 10) {
                                Utils.setDialog(context,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    title: AppLocalizations.of(context)
                                        .enterVerificationCode,
                                    children: [
                                      Text(AppLocalizations.of(context)
                                              .ifYouHaveNotReceivedCode +
                                          ' ' +
                                          AppLocalizations.of(context)
                                              .waitFor5MinsToGetAnotherCode +
                                          '. ' +
                                          AppLocalizations.of(context)
                                              .beInGoodNetwork)
                                    ],
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            primary: Colors.blue),
                                        child: Text(AppLocalizations.of(context)
                                            .cancel),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            primary: Colors.pink),
                                        child: Text(AppLocalizations.of(context)
                                            .exitApp),
                                        onPressed: () {
                                          _timer?.cancel();
                                          Navigator.pop(context);
                                          Navigator.pop(context, false);
                                        },
                                      )
                                    ]);
                              } else {
                                _timer?.cancel();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        Align(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context).verify_code,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.safeBlockVertical * 3.2,
                                  color: Colors.black),
                            )),
                        IconButton(
                            icon: const Icon(
                              Icons.radio,
                              color: Colors.transparent,
                            ),
                            onPressed: () {}),
                      ],
                    ),
                    Padding(
                        padding: EdgeInsets.all(SizeConfig.screenWidth * 0.03),
                        child: Text(
                          verificationMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.blueGrey),
                        )),
                    Padding(
                      padding: EdgeInsets.all(SizeConfig.screenWidth * 0.05),
                      child: Form(
                        key: _formkey,
                        child: TextFormField(
                            autovalidateMode: AutovalidateMode.always,
                            controller: _otpController,
                            maxLines: 1,
                            maxLength: 6,
                            autofocus: false,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)
                                    .enterVerificationCode),
                            validator: (otp) {
                              String error = FormValidators.isOtpValid(otp);
                              if (error != null) {
                                return error;
                              } else if (!otpCodes.contains(otp)) {
                                return AppLocalizations.of(context)
                                    .invalidOtpCode;
                              } else {
                                return null;
                              }
                            },
                            style: TextStyle(
                                color: colorBlack,
                                fontSize: SizeConfig.safeBlockVertical * 2.7),
                            onChanged: (otp) async {
                              _otp = otp.trim();
                              if (_otp.length == 6) {
                                if (otpCodes.contains(_otp)) {
                                  loginUser(widget.currentUser, context);
                                } else if (useFirebasePhone) {
                                  UserCredential userCreds;
                                  try {
                                    PhoneAuthCredential credential =
                                        PhoneAuthProvider.credential(
                                            verificationId: verificationId,
                                            smsCode: _otp);
                                    if (authService.authInstance.currentUser ==
                                        null) {
                                      userCreds = await authService
                                          .signInWithEmailAndPasswordToLinkAccount(
                                              widget.currentUser.email,
                                              widget.currentUser.email);
                                      await userCreds.user
                                          .updatePhoneNumber(credential);
                                    } else {
                                      await authService.authInstance.currentUser
                                          .updatePhoneNumber(credential);
                                    }
                                    loginUser(widget.currentUser, context);
                                  } on FirebaseAuthException catch (e) {
                                    final String errorCode = e.code;
                                    var t = widget.currentUser;
                                    //print('Error1 "$errorCode"');
                                    if ([
                                          'provider-already-linked',
                                          'credential-already-in-use'
                                        ].contains(errorCode) &&
                                        userCreds?.user != null) {
                                      final User user = userCreds.user;
                                      if (user.uid ==
                                              widget
                                                  .currentUser.firebaseUserId &&
                                          user.phoneNumber.endsWith(widget
                                              .currentUser.phoneNumber
                                              .substring(4))) {
                                        loginUser(widget.currentUser, context);
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
                            }),
                      ),
                    ),
                    Utils.customButton(
                      SizeConfig.screenWidth * 0.7,
                      AppLocalizations.of(context).continueText,
                      () {
                        if (_formkey.currentState.validate()) {
                          _formkey.currentState.save();
                          if (_otp != null && otpCodes.contains(_otp)) {
                            loginUser(widget.currentUser, context);
                          } else {
                            Utils.showToast(
                                context,
                                AppLocalizations.of(context).invalidOtpCode,
                                colorError);
                            _formkey.currentState.validate();
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 5),
                    OutlinedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          minimumSize: Size(SizeConfig.screenWidth * 0.7, 38)),
                      onPressed: () {
                        if (_start == 0) {
                          setState(() {
                            _timer?.cancel();
                          });

                          verifyPhoneNumber(widget.currentUser, null);

                          if ('-'.allMatches(widget.currentUser.email).length ==
                              4) {
                            //most likely phone auth failed, sign them in any way.
                            FirebaseMessaging.instance.getToken().then((token) {
                              Map<String, String> params = {
                                'user_id':
                                    widget.currentUser.user_id.toString(),
                                'user_lang': widget.currentUser.user_lang,
                                'to_user_name': widget.currentUser.username,
                                'token': token,
                                'last_verification_code':
                                    '${widget.currentUser.last_verification_code}'
                              };
                              ApiRequest.sendOtpPushNotification(params: params)
                                  .then((code) {
                                setState(() {
                                  otpCodes += '$code';
                                });
                              });
                            });
                            ApiRequest.sendOTPCode(
                                    registrationType: 'phone',
                                    internationlPhoneNumber:
                                        widget.currentUser.phoneNumber,
                                    userName: widget.currentUser.username)
                                .then((user) {
                              setState(() {
                                otpCodes += ',${user.last_verification_code}';
                              });
                            });
                          } else {
                            //they registered with an email, resend otp code.
                            ApiRequest.sendOTPCode(
                                    registrationType: 'email',
                                    email: widget.currentUser.email,
                                    userName: widget.currentUser.username)
                                .then((user) {
                              setState(() {
                                otpCodes += ',${user.last_verification_code}';
                              });
                            });
                          }
                          setState(() {
                            _start = 300;
                          });
                          Utils.showToast(
                              context,
                              AppLocalizations.of(context).newVerificationCode,
                              Colors.green);
                          startTimer();
                        }
                      },
                      child: Text(
                          "${AppLocalizations.of(context).requestNewCode} $_minsSecsTime seconds"),
                    ),
                    showTooManyAttempts
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Text(
                                widget.currentUser.phoneNumber +
                                    " " +
                                    AppLocalizations.of(context)
                                        .tooManyFailures,
                                style: TextStyle(color: Colors.red)),
                          )
                        : const SizedBox.shrink(),
                    showTooManyAttempts && verificationType.contains('email')
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                                AppLocalizations.of(context)
                                    .codeStillValid
                                    .replaceAll('ndesamuelmbah@gmail.com',
                                        widget.currentUser.email),
                                style: TextStyle(color: Colors.green)),
                          )
                        : const SizedBox.shrink()
                  ]),
                )),
          ),
        ),
      ),
    );
  }
}
