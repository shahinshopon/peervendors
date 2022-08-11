import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/form_validators.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/views/chat.dart';
import 'package:peervendors/views/product_details.dart';

class BuyingPage extends StatefulWidget {
  final AdsDetail adsDetail;
  UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  bool intendToAddPhone;

  BuyingPage(
      {Key key,
      @required this.currentUser,
      @required this.cUP,
      @required this.intendToAddPhone,
      @required this.adsDetail})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BuyingPageState();
  }
}

class BuyingPageState extends State<BuyingPage> {
  final firestoreDb = FirestoreDB();
  final _deliveryInstructionsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPhoneNumber = TextEditingController();
  final _otpController = TextEditingController();
  final _addressController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _creatOrderForm = GlobalKey<FormState>();
  String localProfile;
  List<String> otpCodes = [];

  String _email = '', flag = '';
  Map<String, dynamic> country = {};
  Map<String, dynamic> countryInfo = {};
  Map<String, String> reverificationParams = {};
  Map<String, dynamic> chatRoomDetails = {};
  Map<String, String> pushNotificationParams = {};

  bool currentState = false;
  bool shouldShowOtpBox = false;
  bool isEmailReadOnly = false;
  bool isPhoneReadOnly = false;

  Color phoneColor = Colors.black;

  //firebase phone verification
  AuthService authService = AuthService();
  String firebaseVerificationId;
  bool useFirebasePhone = false;
  int firebaseResendToken;
  int lastTimeVerifcationCodeWasSent;
  String verificationId;
  String newNumberPhoneNumber = '';

  int forceResendingToken;
  bool isVerifyingPhone = false;
  bool needsToEnterNewPhone = false;
  bool hasNotVerifiedPhone = true;
  String isPhoneTaken;
  UserModel currentUser;
  bool isLoading = false;
  bool isSubmitting = false;
  Map<String, dynamic> actualAddress = {};
  String newDeviceId;
  AdsDetail currentAd;
  @override
  void initState() {
    currentUser = widget.currentUser;
    currentAd = widget.adsDetail;
    phoneColor = currentUser.phoneNumber.endsWith('0000000000')
        ? Colors.red
        : Colors.black;
    needsToEnterNewPhone = widget.intendToAddPhone;
    setUserPrefs();
    super.initState();
  }

  @override
  void dispose() {
    _deliveryInstructionsController.dispose();
    _phoneController.dispose();
    _newPhoneNumber.dispose();
    _addressController.dispose();
    _quantityController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future setUserPrefs() async {
    countryInfo = Constants.countryLookupMap[currentUser.country_code];
    reverificationParams = {
      'userName': currentUser.username,
      'internationalPhoneNumber': currentUser.phoneNumber,
      'user_id': currentUser.user_id.toString(),
      'email': currentUser.email,
      'isConfirmation': 'no',
      'lang': currentUser.user_lang,
      'firebase_id': currentUser.firebaseUserId
    };

    country = Constants.getCountryInfo(countryCode: currentUser.country_code);
    setState(() {
      flag = country['flag'];
      _email = currentUser.email.split('-').length == 5
          ? 'no@email.proprovided'
          : currentUser.email;
      _phoneController.text = widget.currentUser.phoneNumber;
    });
    getAndSetAddress();
    try {
      String token = await FirebaseMessaging.instance.getToken();
      String updatedDeviceIds =
          UserModel.getUpdatedDeviceIds(token, currentUser.deviceIds);
      if (updatedDeviceIds != currentUser.deviceIds) {
        currentUser.deviceIds = updatedDeviceIds;
        widget.currentUser.deviceIds = updatedDeviceIds;
        ApiRequest.updateUserDevices(
            userId: widget.currentUser.user_id,
            newDeviceToken: updatedDeviceIds);
        await widget.cUP.saveUser(currentUser);
      }
    } catch (e) {}
  }

  Future getAndSetAddress() async {
    if (widget.cUP.canExtractAddress(20, key: "whenAddressForBuy")) {
      Map<String, dynamic> address = await Addresses.getCurrentAddressMap();
      if (address?.isNotEmpty == true) {
        actualAddress = address;
        widget.cUP.saveString("lastFrontAddress", json.encode(address));
        widget.cUP.setTimeWhenEventHappened(eventName: "whenAddressForBuy");
        setAddressData(address);
      }
    } else {
      String p = widget.cUP.getString("lastFrontAddress");
      if (p?.length > 20 == true) {
        Map<String, dynamic> address = json.decode(p);
        setAddressData(address);
      }
    }
  }

  setAddressData(Map<String, dynamic> address) {
    if ('${_addressController.text}'.length < 10) {
      String addressT = Addresses.getKeyFromAddressMap(
              address,
              'locality,subLocality,subAdministrativeArea,thoroughfare,subThoroughfare,administrativeArea',
              'city') +
          ", " +
          Addresses.getKeyFromAddressMap(
              address,
              'administrativeArea,subAdministrativeArea,locality,subLocality',
              'state');
      addressT += ', ${address['isoCountryCode']}-${address['postalCode']}'
          .replaceAll(RegExp(r'\b-?null\b'), '');
      if (addressT.startsWith(', ')) {
        addressT = addressT.substring(2);
      }
      String street = address['street'];
      String name = address['name'];
      if (street != null && street != "Unnamed Road") {
        addressT = "$street, $addressT";
      } else if (name != null && name != "Unnamed Road") {
        addressT = "$name, $addressT";
      }
      _addressController.text = addressT;
    }
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
        title: Text(AppLocalizations.of(context).buy_sell),
        elevation: 2,
      ),
      body: !isLoading
          ? SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(children: [
                Material(
                  elevation: 5,
                  child: ListTile(
                      horizontalTitleGap: 10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProductDetails(
                                    adsDetail: currentAd,
                                    currentUser: widget.currentUser,
                                    cUP: widget.cUP)));
                      },
                      leading: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: Image.network(
                              'https://pvendors.s3.eu-west-3.amazonaws.com/prod_ad_images/${currentAd.images[0]}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, exception, trace) {
                            return Image.asset(
                              'assets/images/img_product_placeholder.jpg',
                              fit: BoxFit.cover,
                            );
                          })),
                      title: Wrap(
                        children: [
                          Text(
                            '${currentAd.price}  ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(currentAd.item_name,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                        ],
                      ),
                      subtitle: Text(currentAd.item_description,
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _creatOrderForm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context).shippingInformation,
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
                            AppLocalizations.of(context).phoneDeliveryNote,
                            color: colorGrey700,
                            fontSize: 12),
                        Container(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(currentUser.username,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold))),
                        buildEditablePhone(context, _phoneController.text,
                            () async {
                          needsToEnterNewPhone = !needsToEnterNewPhone;
                          setState(() {});
                        }),
                        // ElevatedButton(
                        //     child: Text('Test'),
                        //     onPressed: () async {
                        //       print(currentUser.profilePicture);
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
                                    prefixIconConstraints: BoxConstraints(
                                        minWidth: 0, minHeight: 0),
                                    suffixIcon: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 2.0),
                                      child: Container(
                                        height: 40,
                                        width: 42,
                                        decoration:
                                            Utils.containerBoxDecoration(
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
                                                var phoneNumber = countryInfo[
                                                        "dial_code"] +
                                                    FormValidators.trimLeft0(
                                                        localNumb);

                                                if (phoneNumber !=
                                                    currentUser.phoneNumber) {
                                                  var t = await ApiRequest
                                                      .isEmailOrPhoneRegistered(
                                                          internationalPhoneNumber:
                                                              phoneNumber);
                                                  if (t == null) {
                                                    verifyPhoneNumber(
                                                        currentUser,
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
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
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
                                                  email: currentUser.email,
                                                  password:
                                                      authService.pASSWORD);

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
                                        currentUser.phoneNumber =
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
                                            currentUser.email;
                                        final result = await ApiRequest
                                            .sendReverificationCode(
                                                params: reverificationParams);
                                        if (result != null) {
                                          _phoneController.text =
                                              newNumberPhoneNumber;
                                          currentUser.phoneNumber =
                                              newNumberPhoneNumber;
                                          currentUser.user_lang =
                                              AppLocalizations.of(context)
                                                  .localeName;
                                          widget.cUP.saveUser(currentUser);

                                          setState(() {});
                                          Utils.showToast(
                                              context,
                                              AppLocalizations.of(context)
                                                  .authenticationSuccessful,
                                              Colors.green);
                                        }
                                        phoneColor = Colors.black;
                                        currentUser.phoneNumber =
                                            newNumberPhoneNumber;
                                        widget.cUP.saveUser(currentUser);
                                      } on FirebaseAuthException catch (e) {
                                        final errorCode = e.code;
                                        var t = currentUser;
                                        if ([
                                              'provider-already-linked',
                                              'credential-already-in-use'
                                            ].contains(errorCode) &&
                                            userCreds?.user != null) {
                                          final User user = userCreds.user;
                                          if (user.uid ==
                                                  currentUser.firebaseUserId &&
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
                                                'vCode':
                                                    t.last_verification_code,
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
                        Text('✶ ' + AppLocalizations.of(context).enterAddress),
                        buildFormField(context, 100, _addressController, false,
                            TextInputType.streetAddress, (value) {}, (value) {
                          return value.trim().length < 10
                              ? AppLocalizations.of(context)
                                  .enterMinimum2Letters
                                  .replaceAll('2', '10')
                              : null;
                        },
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                color: Colors.blue, size: 25)),
                        Text('✶ ' + AppLocalizations.of(context).itemQuantity),
                        buildFormField(
                            context,
                            4,
                            _quantityController,
                            false,
                            TextInputType.numberWithOptions(),
                            (value) {}, (value) {
                          value = value.trim();
                          var val = num.tryParse(value);
                          if (value.isEmpty || val == null || val <= 0) {
                            return AppLocalizations.of(context).invalid;
                          }
                          return null;
                        }, maxLines: 1, minLength: 1),
                        Text(AppLocalizations.of(context).additionalDelNote),
                        buildFormField(
                            context,
                            100,
                            _deliveryInstructionsController,
                            false,
                            TextInputType.text,
                            (value) {},
                            (value) {},
                            maxLines: 4),

                        SizedBox(height: 20),
                        Center(
                          child: isSubmitting
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  child:
                                      Text(AppLocalizations.of(context).submit),
                                  onPressed: () async {
                                    if (_creatOrderForm.currentState
                                        .validate()) {
                                      String phone = currentUser.phoneNumber
                                              .endsWith('0000000000')
                                          ? widget.currentUser.phoneNumber
                                          : currentUser.phoneNumber;
                                      if (!phone.endsWith('0000000000')) {
                                        setState(() {
                                          isSubmitting = true;
                                        });
                                        if (_addressController.text
                                                .trim()
                                                .length <
                                            10) {
                                          Utils.showToast(
                                              context,
                                              AppLocalizations.of(context)
                                                  .enterAddress,
                                              Colors.pink,
                                              duration: 5);
                                        } else {
                                          Map<String, String> params = {
                                            "orderStatus":
                                                AppLocalizations.of(context)
                                                    .processingOrder,
                                            "buyerName": currentUser.username,
                                            "buyerId":
                                                currentUser.user_id.toString(),
                                            "lang": AppLocalizations.of(context)
                                                .localeName,
                                            "itemId":
                                                currentAd.ad_id.toString(),
                                            "itemName": currentAd.item_name,
                                            "images":
                                                currentAd.images.join('|'),
                                            "countryCode":
                                                currentUser.country_code,
                                            "currencySymbol":
                                                currentUser.currencySymbol,
                                            "email": currentUser.email,
                                            "itemPrice": currentAd.price
                                                .split(' ')
                                                .last
                                                .replaceAll(',', ''),
                                            "quantity":
                                                _quantityController.text.trim(),
                                            "sellerName": currentAd.sellerName,
                                            "sellerId":
                                                currentAd.seller_id.toString(),
                                            "deliveryAddress":
                                                _addressController.text.trim(),
                                            "pickUpLocation":
                                                currentAd.pickUpLocation,
                                            "deliveryInstructions":
                                                _deliveryInstructionsController
                                                    .text
                                                    .trim(),
                                            "buyerPhone": phone,
                                            "orderDateTime": DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString()
                                          };
                                          if (actualAddress?.isNotEmpty ==
                                              true) {
                                            for (String key
                                                in actualAddress.keys) {
                                              params[key] =
                                                  actualAddress[key].toString();
                                            }
                                          }
                                          var t = await ApiRequest.createOrder(
                                              params: params);
                                          if (t != null) {
                                            params['orderId'] = t['orderId']
                                                .toString()
                                                .padLeft(10, "0");
                                            initiateChat(params);
                                            Utils.setDialog(context,
                                                title:
                                                    AppLocalizations.of(context)
                                                        .orderCreated,
                                                children: [
                                                  Text(AppLocalizations.of(
                                                          context)
                                                      .aRepHasBeenAssigedToYourOrder),
                                                  const SizedBox(height: 10),
                                                  Text(AppLocalizations.of(
                                                          context)
                                                      .leaveAShortMessage)
                                                ],
                                                actions: [
                                                  ElevatedButton(
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .yes),
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Navigator.pushReplacement(
                                                        context,
                                                        CupertinoPageRoute(
                                                          builder: (context) => Chat(
                                                              cUP: widget.cUP,
                                                              currentUser:
                                                                  currentUser,
                                                              otherUsersUserId:
                                                                  currentAd
                                                                      .seller_id,
                                                              chatRoomId:
                                                                  chatRoomDetails[
                                                                      'chatRoomId'],
                                                              toUserName: currentAd
                                                                  .sellerName,
                                                              userLang: currentUser
                                                                  .user_lang,
                                                              fromUserName:
                                                                  currentUser
                                                                      .username,
                                                              chatRoomDetails:
                                                                  chatRoomDetails,
                                                              isCustomerService:
                                                                  false,
                                                              image: currentAd
                                                                  .images[0]),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  ElevatedButton(
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .no),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  )
                                                ]);
                                          }
                                        }
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                      } else {
                                        phoneColor = Colors.red;
                                        needsToEnterNewPhone = true;
                                        setState(() {});
                                      }
                                    }
                                  }),
                        ),
                      ],
                    ),
                  ),
                )
              ]),
            )
          : Utils.loadingWidget(AppLocalizations.of(context).savingImage),
    ));
  }

  initiateChat(Map<String, dynamic> orderDetails) {
    List<int> userIds = [currentAd.seller_id, currentUser.user_id];
    userIds.sort();
    List<String> userNames = [currentAd.sellerName, currentUser.username];
    userNames.sort();
    String chatRoomId = '${userIds[0]}_${userIds[1]}';
    int now = DateTime.now().millisecondsSinceEpoch;
    chatRoomDetails = {
      "chatRoomId": chatRoomId,
      "userNames": userNames,
      "userId1": userIds[0],
      "userId2": userIds[1],
      "lastUpdated": now,
      "lastAdImage": currentAd.images[0],
      "lastAdTitle": currentAd.item_name,
      "lastDescription": currentAd.item_description,
      "lastAdPrice": currentAd.price,
      "lastAdId": currentAd.ad_id
    };
    pushNotificationParams = {
      'to_firebase_id': currentAd.seller_id.toString(),
      'title': 'New Message',
      'user_lang': AppLocalizations.of(context).localeName,
      'from_name': currentUser.username,
      'message': "${currentAd.price} ${currentAd.item_name} " +
          AppLocalizations.of(context).wouldLoveToBuyYourItem,
      'is_customer_service': false.toString(),
      'senders_user_id': '${currentUser.user_id}',
      'senders_profile': '${currentUser.profilePicture}',
      'image': currentAd.images[0]
    };
    if (currentUser.user_id == userIds[0]) {
      chatRoomDetails['userProfile1'] = currentUser.profilePicture;
    } else {
      chatRoomDetails['userProfile2'] = currentUser.profilePicture;
    }
    setState(() {});
    firestoreDb.createOrders(orderInfo: orderDetails);
    firestoreDb.addChatRoom(
        chatRoomDetails: chatRoomDetails, chatRoomId: chatRoomId);
    List<Map<String, dynamic>> messages = [
      {
        'sendBy': currentUser.user_id,
        'message':
            "${AppLocalizations.of(context).hello} ${currentUser.username},\n${AppLocalizations.of(context).wouldLoveToBuyYourItem}\n\n'${currentAd.item_name}'\n${currentAd.price}"
      },
      {
        'sendBy': currentUser.user_id,
        'message': AppLocalizations.of(context).haveCreatedAnOrder +
            "\nOrderId: '${orderDetails['orderId']}' \n${AppLocalizations.of(context).letMeKnowIfYouNeedAnythingFromMe}",
      }
    ];
    for (Map<String, dynamic> chatMessageMap in messages) {
      now += 5;
      chatMessageMap['time'] = now;
      firestoreDb.addMessage(chatRoomId, chatMessageMap);
    }
    ApiRequest.sendPushNotification(params: pushNotificationParams);
  }

  TextFormField buildFormField(
      BuildContext context,
      int maxLength,
      TextEditingController _controller,
      bool readOnly,
      TextInputType keyboardType,
      Function(String) onChanged,
      Function(String) validator,
      {Widget prefixIcon,
      Widget suffix,
      int minLength = 6,
      int minLines = 1,
      int maxLines = 2}) {
    return TextFormField(
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      controller: _controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffix: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          isDense: true),
      autovalidateMode: AutovalidateMode.always,
      onChanged: (otp) {
        onChanged(otp);
      },
      validator: (otp) {
        return validator(otp);
        //return validateOtp(otp);
      },
    );
  }

  Widget buildEditablePhone(
      BuildContext context, String text, Function() onPressedFunct,
      {double fontSize = 16}) {
    return Row(
      children: <Widget>[
        Text(text,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.fade,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: phoneColor)),
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
    );
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
    phoneColor = Colors.black;
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
      currentUser.phoneNumber = newPhoneNumber;

      currentUser.user_lang = AppLocalizations.of(context).localeName;
      widget.cUP.saveUser(currentUser);
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
        completeVerification(credential, currentUser, phoneNumber);
      },
      verificationFailed: (FirebaseAuthException e) async {
        final errorCode = e.code;
        if (errorCode == 'too-many-requests') {
          Utils.showToast(
              context, AppLocalizations.of(context).tooManyFailures, Colors.red,
              duration: 6);
          useFirebasePhone = false;
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
}
