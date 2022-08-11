import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/AuthenticationScreens/otp_screen.dart';
import 'package:peervendors/helpers/play_videos.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/default_addresses.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/form_validators.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:video_player/video_player.dart';

import 'login_screen.dart';
import 'package:uuid/uuid.dart';
import '../success_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String googlePhoneNumber;
  final String profilePicture;
  final String deviceId;
  final String uid;
  final String enteredPhone;
  final String enteredEmail;
  final String enteredCountryCode;

  RegistrationScreen(
      {this.name,
      this.email,
      this.googlePhoneNumber,
      this.profilePicture,
      this.deviceId,
      this.uid,
      this.enteredCountryCode,
      this.enteredPhone,
      this.enteredEmail});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  AuthService authService = AuthService();
  FirestoreDB firebaseDB = FirestoreDB();

  String firebaseUserId = Uuid().v4();

  List<bool> _signInSelectedMethods = [true, false];
  bool addressWasExtracted = true;
  bool isGoogleSignUp = false;
  bool isFacebookSignUp = false;
  String registrationType = 'phone';

  String _countryDialCode, _name, _phone, _email;
  final _fullnamecontroller = TextEditingController();
  final _phonenumbercontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _otpController = TextEditingController();
  String checkEmailRegistered, checkPhoneRegistered;
  UserPreferences cUP = UserPreferences();
  String countryCode;
  String otpCodes = '';
  String phoneRegex = '\d{7,7}';
  bool nameIsEditable = true;
  bool phoneIsEditable = true;
  bool emailIsEditable = true;
  bool isEmailRequired = false;
  Map<String, dynamic> currentUserAddress = {};
  String newDeviceId = 'TOKEN_NOT_YET_PROVIDED';

  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;
  UserModel currentUser;
  /*
  *  init state
  * */
  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    setUserPrefs();
  }

  void setLoaingStatus(bool status) {
    setState(() {
      isLoading = status;
    });
  }

  Future setUserPrefs() async {
    await cUP.setUserPreferences();
    currentUser = cUP.getCurrentUser();

    _phonenumbercontroller.text = widget.enteredPhone ?? '';
    _emailcontroller.text = widget.enteredEmail ?? '';

    if (currentUser?.country_code != null ||
        widget.enteredCountryCode?.length == 2) {
      String cc = currentUser?.country_code != null
          ? currentUser.country_code.toUpperCase()
          : widget.enteredCountryCode.toUpperCase();
      Map<dynamic, dynamic> chooseCountry = Constants.countryLookupMap[cc];
      countryCode = cc;
      phoneRegex = chooseCountry['mobile_phone_regex_pattern'];
      _countryDialCode = chooseCountry['dial_code'];

      setState(() {});
    }
    try {
      String t = await FirebaseMessaging.instance.getToken();
      if (t != null) {
        newDeviceId = t;
      }
    } catch (e) {}
    if (widget.name != null) {
      _fullnamecontroller.text = widget.name;
      _name = widget.name;
      nameIsEditable = false;
    }
    if (widget.uid != null) {
      firebaseUserId = widget.uid;
    }
    if (widget.email != null) {
      registrationType = 'email';
      _email = widget.email;
      _emailcontroller.text = widget.email;
      _signInSelectedMethods = [false, true];
      emailIsEditable = false;
    }
    if (widget.googlePhoneNumber != null) {
      _phone = FormValidators.trimLeft0(widget.googlePhoneNumber);
      _phonenumbercontroller.text =
          FormValidators.trimLeft0(widget.googlePhoneNumber);
      phoneIsEditable = false;
    }
    if (widget.enteredCountryCode != null) {}

    otpCodes = await cUP.getLastVerificationCodes();
    if (otpCodes != '') {
      currentUser = cUP.getCurrentUser();
    }
    setState(() {});
    getAndSaveAddress();
  }

  Future updateDevices(UserModel user) async {
    String updatedDeviceIds =
        UserModel.getUpdatedDeviceIds(newDeviceId, user.deviceIds);
    if (updatedDeviceIds != user.deviceIds) {
      user.deviceIds = updatedDeviceIds;
      user.user_lang = AppLocalizations.of(context).localeName;
      await cUP.saveUser(user);
      await ApiRequest.updateUserDevices(
          userId: user.user_id, newDeviceToken: updatedDeviceIds);
    }
  }

  Future getAndSaveAddress() async {
    if (cUP.canExtractAddress(10)) {
      Map<String, dynamic> userAddress =
          await Addresses.getAddressFromBackend();
      if (userAddress != null) {
        cUP.saveString(
            Constants.peerVendorsCurrentAddress, json.encode(userAddress));
        cUP.setTimeWhenEventHappened(
            eventName: Constants.whenAddresLastRequested);
        currentUserAddress = userAddress;
        setNewAddress(userAddress);
      } else {
        addressWasExtracted = false;
        Utils.showToast(context,
            AppLocalizations.of(context).couldNotGetYourLocation, Colors.pink);
        if (countryCode != null && countryCode != 'OT') {
          currentUserAddress =
              DefaultAddresses.getDefaultAddres(countryCode: countryCode);
        }
        initializeVideo();
      }
    } else {
      Map<String, dynamic> userAddress = cUP.getCurrentUserAddress();
      if (userAddress?.isNotEmpty != true &&
          countryCode != null &&
          countryCode != 'OT') {
        currentUserAddress =
            DefaultAddresses.getDefaultAddres(countryCode: countryCode);
      } else {
        setNewAddress(userAddress);
      }
    }
  }

  setNewAddress(Map<String, dynamic> userAddress) {
    if (userAddress?.isNotEmpty == true) {
      currentUserAddress = userAddress;
      if (userAddress['country_code'] != null && countryCode == null) {
        countryCode = userAddress['country_code'];
        var choosenCountry = Constants.countryLookupMap[countryCode];
        if (choosenCountry != null) {
          phoneRegex = choosenCountry['mobile_phone_regex_pattern'];
          _countryDialCode = choosenCountry['dial_code'];
        }
      }
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Utils.loadingWidget(AppLocalizations.of(context).loadingPleaseWait)
        : Scaffold(
            backgroundColor: Colors.blue,
            body: SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(5),
              child: Center(
                child: Container(
                  decoration: Utils.containerBoxDecoration(radius: 15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(children: <Widget>[
                      Utils.buildFormHeader(
                          AppLocalizations.of(context).sign_up, () {
                        Navigator.pop(context);
                      }),
                      AspectRatio(
                        aspectRatio: 0.8,
                        child: Form(
                          autovalidateMode: AutovalidateMode.disabled,
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                buildFullName(),
                                buildToggleButtons(),
                                countryCode == "OT" &&
                                        registrationType != 'email' &&
                                        emailIsEditable
                                    ? Text(
                                        AppLocalizations.of(context)
                                            .emailRequired,
                                        style: TextStyle(
                                            color: Colors.redAccent[200]),
                                      )
                                    : Container(
                                        height: 2,
                                      ),
                                registrationType == 'email'
                                    ? Column(
                                        children: [
                                          buildDropDownButtons(),
                                          SizedBox(
                                              height: SizeConfig.screenHeight *
                                                  0.02),
                                          buildEmailField(),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          buildDropDownButtons(),
                                          SizedBox(height: 5),
                                          buildPhoneNumberField(),
                                        ],
                                      ),
                                SizedBox(
                                    height: SizeConfig.screenHeight * 0.015),
                                Utils.customButton(SizeConfig.screenWidth * 0.5,
                                    AppLocalizations.of(context).sign_up, () {
                                  if (_formKey.currentState.validate()) {
                                    _formKey.currentState.save();
                                    if (countryCode != null &&
                                        countryCode.isNotEmpty) {
                                      currentUserAddress = currentUserAddress ==
                                              null
                                          ? DefaultAddresses.getDefaultAddres(
                                              countryCode: countryCode)
                                          : currentUserAddress;
                                      if (checkEmailRegistered == null) {
                                        signUpCustomer();
                                      }
                                    } else {
                                      Utils.showToast(
                                          context,
                                          AppLocalizations.of(context)
                                              .appNotSupportedInYourCountry,
                                          colorError);
                                    }
                                  }
                                }),
                                SizedBox(
                                    height: SizeConfig.screenHeight * 0.005),
                                RichText(
                                  text: TextSpan(
                                      text: AppLocalizations.of(context)
                                          .alreadyHaveAnAccount,
                                      style: const TextStyle(color: colorBlack),
                                      children: [
                                        TextSpan(
                                          text: AppLocalizations.of(context)
                                              .sign_in,
                                          style: const TextStyle(
                                              color: Colors.blue),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (_) =>
                                                        LoginScreen())),
                                        )
                                      ]),
                                ),
                                addressWasExtracted
                                    ? const SizedBox.shrink()
                                    : OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.play_circle_fill_outlined,
                                          color: Colors.red,
                                        ),
                                        onPressed: playVideo,
                                        label: Text(
                                          AppLocalizations.of(context)
                                              .fixMyLocationProblem,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            )),
          );
  }

  Future<bool> authenticateUserViaFirebase({String userEmail}) async {
    String authenticatedUser = await authService.signInWithEmailAndPassword(
        userEmail.toLowerCase(), userEmail.toLowerCase());
    if (authenticatedUser != null) {
      return true;
    } else {
      return false;
    }
  }

  void setLoadingState(bool loadingState) {
    setState(() {
      isLoading = loadingState;
    });
  }

  saveUserAndGoToSuccessScreen(UserModel userModel) async {
    userModel.user_lang = AppLocalizations.of(context).localeName;
    if (newDeviceId != null && !userModel.deviceIds.contains(newDeviceId)) {
      updateDevices(userModel);
    }
    cUP.saveUser(userModel);
    await ApiRequest.activateUserAccount(userModel.user_id);
    await cUP.saveString(Constants.peerVendorsUser, json.encode(userModel));
    await cUP.setBool(key: Constants.peerVendorsAccountStatus, value: true);
    await authenticateUserViaFirebase(userEmail: userModel.email);
    setLoadingState(false);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SuccessScreen()));
  }

  signUpCustomer() async {
    setLoadingState(true);
    if (currentUserAddress != null && currentUserAddress.length > 2) {
      Map<String, dynamic> savedAddress = cUP.getCurrentUserAddress();
      createUserFastApi(savedAddress, firebaseUserId: firebaseUserId)
          .then((UserModel userModel) async {
        if (userModel != null) {
          currentUser = userModel;
          otpCodes += ',${userModel.last_verification_code}';
          await Future.wait([
            cUP.setTimeWhenEventHappened(
                eventName: Constants.whenLastVerificationCodeWasSent),
            cUP.saveString(Constants.peerVendorsLastVCodes, otpCodes)
          ]);
          userModel.user_lang = AppLocalizations.of(context).localeName;
          if (!phoneIsEditable || !emailIsEditable) {
            saveUserAndGoToSuccessScreen(userModel);
          } else {
            await cUP.saveUser(userModel);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    OtpScreen(currentUser: userModel, canVerifyPhone: true)));
            setLoadingState(false);
          }
        } else {
          if (registrationType == 'phone') {
            checkPhoneRegistered = AppLocalizations.of(context).phoneNumber +
                ' ' +
                AppLocalizations.of(context).alreadyExists +
                ', ' +
                AppLocalizations.of(context).sign_in;
            _formKey.currentState.validate();
          } else {
            checkEmailRegistered = AppLocalizations.of(context).email +
                ' ' +
                AppLocalizations.of(context).alreadyExists +
                ', ' +
                AppLocalizations.of(context).sign_in;
            _formKey.currentState.validate();
          }
          firebaseUserId = widget.uid == null ? Uuid().v4() : widget.uid;
          setLoadingState(false);
          Utils.showToast(context,
              AppLocalizations.of(context).unableToCreateUser, colorError);
        }
      }).catchError((futureError) {
        firebaseUserId = widget.uid == null ? Uuid().v4() : widget.uid;
        setLoadingState(false);
      });
    } else if (currentUserAddress == null || currentUserAddress.length < 2) {
      Utils.showToast(
          context,
          AppLocalizations.of(context).unableToCreateUser +
              '  \n' +
              AppLocalizations.of(context).location +
              ' ' +
              AppLocalizations.of(context).permissionsNeeded,
          colorError);
      setLoadingState(false);
      initializeVideo();
    }
  }

  @override
  void dispose() {
    _fullnamecontroller.dispose();
    _phonenumbercontroller.dispose();
    _emailcontroller.dispose();
    _otpController.dispose();
    if (_videoController != null &&
        (_videoController.value != null ||
            _videoController.value.isInitialized)) {
      _videoController.dispose();
    }
    super.dispose();
  }

  void initializeVideo() {
    if (_videoController == null || !_videoController.value.isInitialized) {
      String languageCode = Localizations.localeOf(context).languageCode;
      String videoUrl = Utils.getVideoUrl('signUpOrLogIn', languageCode);
      _videoController = VideoPlayerController.network(videoUrl);
      _initializeVideoPlayerFuture = _videoController.initialize();
      // Use the controller to loop the video
      _videoController.setLooping(true);
    }
  }

  Future playVideo() {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => Expanded(
          flex: 1,
          child: AlertDialog(
            contentPadding: const EdgeInsets.only(left: 2, right: 2),
            titlePadding: const EdgeInsets.all(5),
            title: SizedBox(
                height: 30,
                child: Text(AppLocalizations.of(context).helpCenter,
                    textAlign: TextAlign.center)),
            actions: [
              SizedBox(
                  height: 35,
                  child: TextButton(
                      onPressed: () {
                        if (_videoController.value != null &&
                            (_videoController.value.isInitialized ||
                                _videoController.value.isPlaying)) {
                          _videoController.pause();
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context).gotIt)))
            ],
            content: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_videoController),
                  ClosedCaption(text: _videoController.value.caption.text),
                  ControlsOverlay(controller: _videoController),
                  VideoProgressIndicator(_videoController,
                      allowScrubbing: true),
                ],
              ),
            ),
          )),
    );
  }

  onChangeEmail(String email) {
    checkEmailRegistered = null;
    if (email != null && email.isNotEmpty && email.length > 5) {
      email = email.trim();
      if (FormValidators.isAValidEmail(email)) {
        //debugPrint('\nAPI has been called\n');
        ApiRequest.isEmailOrPhoneRegistered(email: email).then((returnedUser) {
          if (returnedUser != null) {
            checkEmailRegistered = 'Email already registered';
          } else {
            checkEmailRegistered = null;
          }
        });
      } else {
        checkEmailRegistered = null;
      }
    }
    setState(() {});
  }

  Future<bool> createUserViaFirebase({String userEmail}) async {
    try {
      String authenticatedUser =
          await authService.createUserWithEmailAndPassword(
              userEmail.toLowerCase(), userEmail.toLowerCase());
      if (authenticatedUser != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> createUserFastApi(Map<String, dynamic> userAddress,
      {String firebaseUserId}) async {
    userAddress =
        userAddress?.isNotEmpty == true ? userAddress : currentUserAddress;
    Map<String, String> map = {
      "username": _name,
      "country_code": countryCode,
      "user_lang": AppLocalizations.of(context).localeName,
      "city": userAddress['city'],
      "state": userAddress['state'],
      "address_id": userAddress['address_id'].toString(),
      "firebase_id": firebaseUserId,
      "device_ids": newDeviceId,
      "use_firebase_verification": true.toString()
    };
    if (currentUserAddress == null || currentUserAddress.isEmpty) {
      currentUserAddress =
          DefaultAddresses.getDefaultAddres(countryCode: countryCode);
      map["city"] = currentUserAddress['city'];
      map["state"] = currentUserAddress['state'];
      map["address_id"] = currentUserAddress['address_id'].toString();
    }
    if ('$newDeviceId'.length < 30) {
      map['device_ids'] = 'TOKEN_NOT_YET_PROVIDED';
    }
    _phone = FormValidators.trimLeft0(_phone);
    _email = _email == null || _email.length < 6 ? null : _email;

    if (_phone == '' && _email == null) {
      return null;
    } else if (_phone == '' && _email != null) {
      map["phone_number"] = _countryDialCode + '0000000000';
      map['email'] = _email; //firebaseUserId+'@gmail.com';
    } else if (_phone != '' && _email == null) {
      map["email"] = firebaseUserId + '@gmail.com';
      map["phone_number"] = _countryDialCode + _phone.replaceAll('+', '');
    } else if (_phone != '' && _email != null) {
      map["email"] = _email;
      map["phone_number"] = _countryDialCode + _phone.replaceAll('+', '');
    }

    if (!emailIsEditable) {
      map['email'] = widget.email;
      map['is_facebook_or_google_login'] = true.toString();
    }
    if (!phoneIsEditable) {
      map['phone_number'] = '+' + widget.googlePhoneNumber.replaceAll('+', '');
      map['is_facebook_or_google_login'] = true.toString();
    }
    if (widget.profilePicture != null) {
      map['profile_picture'] = widget.profilePicture;
    }
    map['registrationType'] = registrationType;
    //print(map);
    List<String> createUserResponse = await ApiRequest.createCustomer(map);
    if (createUserResponse != null &&
        createUserResponse.length == 2 &&
        createUserResponse[1] == '200') {
      final UserModel userModel =
          UserModel.fromJson(json.decode(createUserResponse[0]));
      return userModel;
    } else {
      return null;
    }
  }

  Widget buildFullName() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: TextFormField(
          controller: _fullnamecontroller,
          enabled: nameIsEditable,
          maxLines: 1,
          maxLength: 30,
          autofocus: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context).fullName),
          validator: (fullName) {
            return widget.name != null
                ? null
                : FormValidators.isAValidFullName(fullName);
          },
          style: const TextStyle(color: colorBlack, fontSize: 15),
          onSaved: (value) => _name = value,
        ));
  }

  Widget buildPhoneNumberField() {
    return phoneIsEditable
        ? Container(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  _countryDialCode != null ? _countryDialCode : '    ',
                  style: TextStyle(
                      color: Theme.of(context).accentColor, fontSize: 16),
                ),
              ),
              SizedBox(width: SizeConfig.screenWidth * 0.03),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.screenWidth * 0.03,
                      right: SizeConfig.screenWidth * 0.03),
                  child: TextFormField(
                    controller: _phonenumbercontroller,
                    enabled: phoneIsEditable,
                    maxLines: 1,
                    autofocus: false,
                    autovalidateMode: AutovalidateMode.always,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).phoneNumber),
                    validator: (phoneNumber) {
                      if (widget.googlePhoneNumber != null) {
                        return null;
                      }
                      if (phoneNumber == null || phoneNumber.isEmpty) {
                        return AppLocalizations.of(context).phoneNumber;
                      } else if (checkPhoneRegistered != null) {
                        return checkPhoneRegistered;
                      } else if (phoneRegex == '\d{7,7}') {
                        return AppLocalizations.of(context).selectYourCountry;
                      } else if (FormValidators.isValidPhoneNumber(
                              phoneNumber: phoneNumber,
                              phoneRegex: phoneRegex) !=
                          null) {
                        return AppLocalizations.of(context).phoneNumber +
                            ' ' +
                            AppLocalizations.of(context).invalid;
                      }
                      return null;
                    },
                    style: TextStyle(color: colorBlack, fontSize: 15),
                    onSaved: (phone) => _phone = phone,
                    onChanged: (phone) {
                      checkPhoneRegistered = null;
                    },
                  ),
                ),
              ),
            ],
          ))
        : Container(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.screenWidth * 0.03,
                      right: SizeConfig.screenWidth * 0.03),
                  child: TextFormField(
                    controller: _phonenumbercontroller,
                    enabled: phoneIsEditable,
                    maxLines: 1,
                    autofocus: false,
                    autovalidateMode: AutovalidateMode.always,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).phoneNumber),
                    validator: (phoneNumber) {
                      if (phoneNumber == null || phoneNumber.isEmpty) {
                        return AppLocalizations.of(context).phoneNumber;
                      } else if (phoneRegex == '\d{7,7}') {
                        return AppLocalizations.of(context).selectYourCountry;
                      } else if (FormValidators.isValidPhoneNumber(
                              phoneNumber: phoneNumber,
                              phoneRegex: phoneRegex) !=
                          null) {
                        return AppLocalizations.of(context).phoneNumber +
                            ' ' +
                            AppLocalizations.of(context).invalid;
                      } else if (checkPhoneRegistered != null) {
                        return checkPhoneRegistered;
                      }
                      return null;
                    },
                    style: TextStyle(color: colorBlack, fontSize: 15),
                    onSaved: (phone) => _phone = phone,
                  ),
                ),
              ),
            ],
          ));
  }

  Widget buildDropDownButtons() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14.5),
        decoration: Utils.containerBoxDecoration(
            borderWidth: 2, borderColor: Colors.blue, radius: 20),
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
                  if (currentUserAddress == null ||
                      currentUserAddress.length < 3) {
                    currentUserAddress =
                        DefaultAddresses.getDefaultAddres(countryCode: country);
                  }
                  phoneRegex = chooseCountry['mobile_phone_regex_pattern'];
                  _countryDialCode = dailCode;
                });

                if (widget.googlePhoneNumber != null &&
                    widget.googlePhoneNumber.startsWith(dailCode)) {
                  setState(() {
                    _phonenumbercontroller.text =
                        widget.googlePhoneNumber.substring(dailCode.length);
                  });
                }
                if (country == "OT" &&
                    registrationType != 'email' &&
                    emailIsEditable) {
                  Utils.showToast(context,
                      AppLocalizations.of(context).emailRequired, Colors.pink);
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (country) {
                if (country != null) {
                  Map<dynamic, dynamic> chooseCountry =
                      Constants.countryLookupMap[country];
                  String dailCode = chooseCountry['dial_code'];
                  if (country == "OT" &&
                      registrationType != 'email' &&
                      emailIsEditable) {
                    return AppLocalizations.of(context).emailRequired;
                  }
                  if (widget.googlePhoneNumber != null) {
                    if (!widget.googlePhoneNumber.startsWith(dailCode)) {
                      return AppLocalizations.of(context).invalid +
                          ' ' +
                          AppLocalizations.of(context).selectYourCountry;
                    } else {
                      return null;
                    }
                  } else {
                    return null;
                  }
                } else {
                  return AppLocalizations.of(context).selectYourCountry;
                }
              },
              items: Constants.countryLookupMap.entries.map((kvpair) {
                return DropdownMenuItem<String>(
                  value: kvpair.key,
                  // value: _mySelection,
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
                              : Text(kvpair.value["country_name"])),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ));
  }

  Widget buildEmailField() {
    return Padding(
        padding: EdgeInsets.only(
            left: SizeConfig.screenWidth * 0.015,
            right: SizeConfig.screenWidth * 0.015),
        child: TextFormField(
          controller: _emailcontroller,
          enabled: emailIsEditable,
          maxLines: 1,
          autofocus: false,
          autovalidateMode: AutovalidateMode.always,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context).email),
          validator: (email) {
            if (widget.email != null) {
              return null;
            }
            if (email == null || email.isEmpty) {
              return AppLocalizations.of(context).enterYourEmailAddress;
            } else if (phoneRegex == '\d{7,7}') {
              return AppLocalizations.of(context).selectYourCountry;
            } else if (!FormValidators.isAValidEmail(email)) {
              return AppLocalizations.of(context).pleaseEnterAValidEmail;
            } else if (checkEmailRegistered != null) {
              return checkEmailRegistered;
            }
            return null;
          },
          style: const TextStyle(color: colorBlack, fontSize: 15),
          onChanged: onChangeEmail,
          onSaved: (value) => _email = value,
        ));
  }

  Widget buildToggleButtons() {
    return ToggleButtons(
      children: [
        Utils.toggleButtonChild([
          Icon(Icons.phone),
          Text('Phone', style: TextStyle(color: Colors.black))
        ]),
        Utils.toggleButtonChild([
          Text('Email', style: TextStyle(color: Colors.black)),
          Icon(Icons.email)
        ]),
      ],
      isSelected: _signInSelectedMethods,
      onPressed: (int index) {
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
}
