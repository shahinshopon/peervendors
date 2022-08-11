import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/io_client.dart';
import 'package:peervendors/helpers/play_videos.dart';
import 'package:video_player/video_player.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/AuthenticationScreens/login_screen.dart';
import 'package:peervendors/AuthenticationScreens/registration_screen.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/helpers/auth.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/dialogs/progress_dialog.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/success_screen.dart';
import 'package:peervendors/views/privacy_or_faqs.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:uuid/uuid.dart';

class SignupOrLogin extends StatefulWidget {
  const SignupOrLogin({Key key}) : super(key: key);

  @override
  SignupOrLoginState createState() => SignupOrLoginState();
}

class SignupOrLoginState extends State<SignupOrLogin> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  static IOClient https() {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }
  //final FacebookLogin facebookLogin = FacebookLogin();

//   final TwitterCreds twitterCreds = TwitterCreds();
//   final Map<String, String> twitterCreds = {'API_KEY': 'uGxOLKbF6XOSZN35mtwMbXMY5',
//  'API_SECRET_KEY': 'eHU3WBX9FLRg1JEDSzGxPSGGHnDOMMtfBzuXHeCy19ELzVAFY6',
//  'BEARER_TOKEN': 'AAAAAAAAAAAAAAAAAAAAAALRQwEAAAAAGvZZowZsIpTFrzBCIdiWRXMdMOw%3Dx8rLHRjw9aEuYO8YLpjtk1JutZWWzAYCZ8vg00Z1wnGqlhlnvm',
//  'ACCESS_TOKEN': '4100575054-Q9mzWo9rBAE03hYwfiPI9fpPgvhmTXHnxxOM9Gx',
//  'ACCESS_TOKEN_SECRET': 'SyOUHCtwkXRAwsmS7b8zPc1kMfKXGNL8BnPBN2FrGZUs5'};
//   final TwitterLogin twitterLogin = TwitterLogin( consumerKey: '0bx3o3xijhjhzGQ4PT1X7kKWC', consumerSecret:'3Gm4HotUPhdP2vdwZqo3NQaaEzOts5LzAjffuuRBtTo0qanqnu');
  // final TwitterLogin twitterLogin = TwitterLogin( consumerKey: TwitterCreds.API_KEY, consumerSecret:TwitterCreds.API_SECRET_KEY);
  final AuthService authService = AuthService();
  UserPreferences cUP = UserPreferences();
  UserModel currentUser;

  final String backendPhoto = Uuid().v4() + '.jpg';
  String newDeviceId;
  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

// flutter twitter login nothing to see here. Looks like this page doesn't exist.
  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _videoController.dispose();
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

  Future setUserPrefs() async {
    try {
      newDeviceId = await FirebaseMessaging.instance.getToken();
    } catch (e) {}
    //print('Token is $newDeviceId');
    await cUP.setUserPreferences();
    currentUser = cUP.getCurrentUser();
    setState(() {});
    getAndSaveAddress();
  }

  Future getAndSaveAddress() async {
    if (cUP.canExtractAddress(5)) {
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

  @override
  Widget build(BuildContext context) {
    initializeVideo();
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                decoration: Utils.containerBoxDecoration(radius: 10),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      buildSignInIcon(context,
                          text: AppLocalizations.of(context).sign_in,
                          signUpOrIn: 'sign in'),
                      buildSignInIcon(context,
                          text: AppLocalizations.of(context).sign_up,
                          signUpOrIn: 'sign up'),
                      Text(
                        AppLocalizations.of(context).orContinueWith,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      buildSocialSignInButton(context, 'Facebook'),
                      buildSocialSignInButton(context, 'Google'),
                      buildSocialSignInButton(context, 'Twitter'),
                      Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .privacyPolicyNote
                                  .split('|')
                                  .first,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .privacyPolicyNote
                                        .split('|')
                                        .last,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.blue),
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (_) =>
                                            PrivacyOrFAQs(isPrivacy: true)))),
                          ]),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: TextButton.icon(
                              icon: const Icon(
                                Icons.play_circle_fill_outlined,
                                color: Colors.red,
                              ),
                              onPressed: playVideo,
                              label: Text(
                                AppLocalizations.of(context).needHelp,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void completeSocialSignIn(
      String socialCompany, UserCredential userCredentials) async {
    User googleUser = userCredentials != null ? userCredentials.user : null;

    if (googleUser != null) {
      if (googleUser.email != null && googleUser.email.isNotEmpty) {
        if (currentUser != null &&
            googleUser.email.toLowerCase() == currentUser.email) {
          if (googleUser.photoURL != null &&
              currentUser.profilePicture == 'default_profile_picture.jpg') {
            String profilePicture =
                await saveSocialProfilePictureToBackend(googleUser.photoURL);
            if (profilePicture != null) {
              currentUser.profilePicture = profilePicture;
              saveUserAndGoToSuccessScreen(currentUser);
            } else {
              saveUserAndGoToSuccessScreen(currentUser);
            }
          } else {
            saveUserAndGoToSuccessScreen(currentUser);
          }
        } else {
          UserModel alreadyRegisteredUser =
              await ApiRequest.isEmailOrPhoneRegistered(
                  email: googleUser.email);
          if (alreadyRegisteredUser != null) {
            //print( '\n\n Sav and go to Success Screen');
            if (alreadyRegisteredUser.profilePicture ==
                'default_profile_picture.jpg') {
              String profilePicture =
                  await saveSocialProfilePictureToBackend(googleUser.photoURL);
              if (profilePicture != null) {
                alreadyRegisteredUser.profilePicture = profilePicture;
                saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
              } else {
                saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
              }
            } else {
              saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
            }
          } else {
            String profilePicture =
                await saveSocialProfilePictureToBackend(googleUser.photoURL);
            Utils.showToast(context,
                AppLocalizations.of(context).selectYourCountry, Colors.green);
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => RegistrationScreen(
                    name: googleUser.displayName,
                    email: googleUser.email,
                    googlePhoneNumber: googleUser.phoneNumber,
                    profilePicture: profilePicture,
                    uid: googleUser.uid),
              ),
            );
          }
        }
      } else if (googleUser.phoneNumber != null &&
          googleUser.phoneNumber.isNotEmpty) {
        if (currentUser != null &&
            currentUser.phoneNumber
                .contains(googleUser.phoneNumber.substring(5))) {
          if (googleUser.photoURL != null &&
              currentUser.profilePicture == 'default_profile_picture.jpg') {
            String profilePicture =
                await saveSocialProfilePictureToBackend(googleUser.photoURL);
            if (profilePicture != null) {
              currentUser.profilePicture = profilePicture;
              saveUserAndGoToSuccessScreen(currentUser);
            } else {
              saveUserAndGoToSuccessScreen(currentUser);
            }
          } else {
            saveUserAndGoToSuccessScreen(currentUser);
          }
        } else {
          UserModel alreadyRegisteredUser =
              await ApiRequest.isEmailOrPhoneRegistered(
                  internationalPhoneNumber: googleUser.phoneNumber);
          if (alreadyRegisteredUser != null) {
            if (alreadyRegisteredUser.profilePicture ==
                'default_profile_picture.jpg') {
              String profilePicture =
                  await saveSocialProfilePictureToBackend(googleUser.photoURL);
              if (profilePicture != null) {
                alreadyRegisteredUser.profilePicture = profilePicture;
                saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
              } else {
                saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
              }
            } else {
              saveUserAndGoToSuccessScreen(alreadyRegisteredUser);
            }
          } else {
            String profilePicture =
                await saveSocialProfilePictureToBackend(googleUser.photoURL);
            Utils.showToast(context,
                AppLocalizations.of(context).selectYourCountry, Colors.green,
                duration: 6);
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => RegistrationScreen(
                    name: googleUser.displayName,
                    email: googleUser.email,
                    googlePhoneNumber: googleUser.phoneNumber,
                    profilePicture: profilePicture,
                    uid: googleUser.uid),
              ),
            );
          }
        }
      } else {
        String profilePicture =
            await saveSocialProfilePictureToBackend(googleUser.photoURL);
        Utils.showToast(
            context,
            '${AppLocalizations.of(context).selectYourCountry}, ${AppLocalizations.of(context).email}, ${AppLocalizations.of(context).or}, ${AppLocalizations.of(context).phoneNumber}',
            Colors.green,
            duration: 6);
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => RegistrationScreen(
                name: googleUser.displayName,
                email: googleUser.email,
                googlePhoneNumber: googleUser.phoneNumber,
                profilePicture: profilePicture,
                uid: googleUser.uid),
          ),
        );
      }
    } else {
      Utils.showToast(
          context,
          '$socialCompany ${AppLocalizations.of(context).loginFailed}',
          Colors.red);
      Navigator.pop(context, false);
    }
  }

  Widget buildSocialSignInButton(BuildContext context, String socialCompany) {
    Color color = Colors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      child: GestureDetector(
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              signInWithSocial(socialCompany).then((userCredentials) async {
                completeSocialSignIn(socialCompany, userCredentials);
              }).catchError((e) {
                Navigator.pop(context, false);
              });
              return WillPopScope(
                onWillPop: () => Future.value(false),
                child: ProgressDialog(
                    message: AppLocalizations.of(context).loadingPleaseWait),
              );
            },
          );
        },
        child: Container(
          height: 45,
          decoration: Utils.containerBoxDecoration(
              borderColor: Colors.indigoAccent, radius: 20),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const SizedBox(width: 15),
              'Twitter' == socialCompany
                  ? Icon(FontAwesomeIcons.twitter, color: Colors.blue[400])
                  : 'Facebook' == socialCompany
                      ? Icon(FontAwesomeIcons.facebook, color: Colors.blue[700])
                      : Image.asset(
                          'assets/images/${socialCompany.toLowerCase()}.png',
                          height: 40,
                        ),
              const SizedBox(width: 10),
              Text('${AppLocalizations.of(context).signInWith} $socialCompany',
                  style: TextStyle(color: color, fontSize: 18))
            ],
          ),
        ),
      ),
    );
  }

  Future playVideo() {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
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
            //fit: StackFit.expand,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              VideoPlayer(_videoController),
              ClosedCaption(text: _videoController.value.caption.text),
              ControlsOverlay(controller: _videoController),
              VideoProgressIndicator(_videoController, allowScrubbing: true),
            ],
          ),
        ),
      ),
    );
  }

  saveUserAndGoToSuccessScreen(UserModel userModel) async {
    userModel.user_lang = AppLocalizations.of(context).localeName;
    if (newDeviceId != null && !userModel.deviceIds.contains(newDeviceId)) {
      String updatedDeviceIds =
          UserModel.getUpdatedDeviceIds(newDeviceId, userModel.deviceIds);
      if (updatedDeviceIds != userModel.deviceIds) {
        userModel.deviceIds = updatedDeviceIds;
        await cUP.saveUser(userModel);
        ApiRequest.updateUserDevices(
            userId: userModel.user_id, newDeviceToken: updatedDeviceIds);
      }
    }
    cUP.saveUser(userModel);
    cUP.setBool(key: Constants.peerVendorsAccountStatus, value: true);

    Future.wait([
      ApiRequest.activateUserAccount(userModel.user_id),
      authenticateUserViaFirebase(userEmail: userModel.email)
    ]);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SuccessScreen()));
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

  Future<String> saveSocialProfilePictureToBackend(String photoUrl) async {
    if (photoUrl != null && backendPhoto.length > 15) {
      Map<String, String> params = {
        'photo_url': photoUrl,
        's3id': backendPhoto
      };
      ApiRequest.saveSocialProfilePictureUrl(params: params);
      return backendPhoto;
    } else {
      return null;
    }
  }

  Widget buildSignInIcon(BuildContext context,
      {@required String text, @required String signUpOrIn}) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: ElevatedButton(
          style: Utils.roundedButtonStyle(),
          child: Center(
            child: Container(
                alignment: Alignment.center,
                height: 45,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                  textAlign: TextAlign.center,
                )),
          ),
          onPressed: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => signUpOrIn == 'sign in'
                        ? LoginScreen()
                        : RegistrationScreen()));
          },
        ));
  }

  Future<UserCredential> signInWithSocial(String socialCompany) async {
    String differentAccountCreds = 'account-exists-with-different-credential';
    // Trigger the sign-in flow
    if (socialCompany == 'Facebook') {
      final LoginResult loginResult = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);
      if (loginResult.status == LoginStatus.success) {
        // Create a credential from the access token
        //print('Passed credential: ${loginResult.accessToken.token}');
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(loginResult.accessToken.token);
        // Once signed in, return the UserCredential
        try {
          UserCredential cred = await FirebaseAuth.instance
              .signInWithCredential(facebookAuthCredential);
          return cred;
        } catch (e) {
          if (e.code == differentAccountCreds) {
            String token = loginResult.accessToken.token;
            Uri facebookUri = Uri.parse(
                'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,picture.height(800),email&access_token=$token');
            http.Response graphResponse = await https().get(facebookUri);
            Map<String, dynamic> facebookUser = graphResponse.statusCode == 200
                ? json.decode(graphResponse.body)
                : null;
            if (facebookUser.isNotEmpty) {
              UserCredential uc = await AuthService()
                  .signInWithEmailAndPasswordToLinkAccount(
                      facebookUser['email'], '');
              return FirebaseAuth.instance.currentUser
                  .linkWithCredential(facebookAuthCredential);
            } else {
              return null;
            }
          } else {
            return null;
          }
        }
      } else {
        Utils.showToast(
            context,
            '$socialCompany ${AppLocalizations.of(context).loginFailed} ${loginResult.status}',
            Colors.red);
        return null;
      }
    } else if (socialCompany == 'Google') {
      try {
        GoogleSignInAccount _googleSignInAccount = await googleSignIn.signIn();
        if (_googleSignInAccount != null) {
          GoogleSignInAuthentication _googleSignInAuthentication =
              await _googleSignInAccount.authentication;
          AuthCredential _authCredential = GoogleAuthProvider.credential(
            accessToken: _googleSignInAuthentication.accessToken,
            idToken: _googleSignInAuthentication.idToken,
          );
          return FirebaseAuth.instance.signInWithCredential(_authCredential);
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
      final twitterLogin = TwitterLogin(
          apiKey: TwitterCreds.apiKey,
          apiSecretKey: TwitterCreds.apiSecretKey,
          redirectURI: TwitterCreds.twittersdk);

      // Trigger the sign-in flow
      final authResult = await twitterLogin.login();
      if (authResult.status == TwitterLoginStatus.loggedIn) {
        // Create a credential from the access token
        OAuthCredential twitterAuthCredential = TwitterAuthProvider.credential(
          accessToken: authResult.authToken,
          secret: authResult.authTokenSecret,
        );
        // Once signed in, return the UserCredential
        try {
          UserCredential cred = await FirebaseAuth.instance
              .signInWithCredential(twitterAuthCredential);
          return cred;
        } catch (e) {
          if (e.code == differentAccountCreds) {
            final twitterUser = authResult.user;
            if (twitterUser.email != null) {
              UserCredential uc = await AuthService()
                  .signInWithEmailAndPasswordToLinkAccount(
                      twitterUser.email, '');
              return FirebaseAuth.instance.currentUser
                  .linkWithCredential(twitterAuthCredential);
            } else {
              return null;
            }
          } else {
            return null;
          }
        }
      } else {
        Utils.showToast(
            context,
            '$socialCompany ${AppLocalizations.of(context).loginFailed} ${authResult.status}',
            Colors.red);
        return null;
      }
    }
  }
}

class TwitterCreds {
  static const String apiKey = 'JaLUbcBAlHKm7Z6XvQHDbewrH';
  static const String apiSecretKey =
      'sQMquWChfimaYCU3ZRfAOlWbleZ18WpTMBRDLjY7CpVQgjKLP5';
  static const String bearerToken =
      'AAAAAAAAAAAAAAAAAAAAAALRQwEAAAAAqnngnFXGVkZ7Z216jK4vQAnz9I4%3DYjaXsOGPE4fAzewKSLrTq6GTSiYoAY9L6bRbF06kcGqfKzD7mq';

  static const String accessToken =
      '4100575054-Z0DdXiN12DBmnLAoVHoXpyKFdhlDL78FarLmn3m';
  static const String accessTokenSecret =
      'gRVHBTWU19qzetRnBzO9qwDUpjY6F3LjGhADzYHGcwhKP';
  static const String callbackURL =
      'https://peer-vendors-b09c1.firebaseapp.com/__/auth/handler';
  static const String twittersdk = 'twittersdk://';
}

class YahooCreds {
  static const String appID = 'XFt2vGUo';
  static const String clientIdOrConsumerKey =
      'dj0yJmk9VjExWUtNR0RFcGNaJmQ9WVdrOVdFWjBNblpIVlc4bWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTAz';
  static const String clientSecretOrConsumerSecret =
      'c6dce5055ef2087f223f4dc241e22c30278cca2a';
  static const String callbackURL =
      'https://peer-vendors-b09c1.firebaseapp.com/__/auth/handler';
}
