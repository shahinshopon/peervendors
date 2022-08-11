import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/models/user_model.dart';
import 'HomeScreen/botton_nav_controller.dart';
import 'SplashScreen/splash.dart';
//Phone Auth YouTube: ** https://www.youtube.com/watch?v=PEUUYOQ2Ixo
//***** https://www.youtube.com/watch?v=4Cwp1iA8BaQ&t=631s
// push notification https://www.youtube.com/watch?v=pVUIU_nq8MU

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'general_notification_channel_id', // id
    'App Updates', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
    enableLights: true);
const AndroidNotificationChannel privacyAndSecurity =
    AndroidNotificationChannel(
        'general_notification_channel_id', // id
        'Privacy and Security', // title
        'This channel is used for important notifications.', // description
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableLights: true);
const AndroidNotificationChannel newMessageNotification =
    AndroidNotificationChannel(
        'new_message_alert', // id
        'New Message', // title
        'We use this channel to inform you when someone sends you a message on Peer Vendors', // description
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('newmessage'),
        enableLights: true);
const AndroidNotificationChannel productTooOld = AndroidNotificationChannel(
    'product_too_old', // id
    'Product Listings Update', // title
    'Peer Vendors Want you to Update Your Listings', // description
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('goodmorning'),
    enableLights: true);
const AndroidNotificationChannel generalNotificationChannel =
    AndroidNotificationChannel(
        'general_notification_channel', // id
        'General Notifications', // title
        'Peer Vendors General Notifications like Privacy and Security', // description
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('littledwarf'),
        enableLights: true);

AndroidNotificationChannel getAndroidNotificationChannel(String sound) {
  //print('get channel called');
  if (sound == 'notification_sound') {
    return defaultChannel;
  } else if (sound == 'newmessage') {
    return newMessageNotification;
  } else if (sound == 'product_too_old') {
    return productTooOld;
  } else {
    return generalNotificationChannel;
  }
}

/// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
saveNotification(Map<String, dynamic> notification) {
  UserPreferences cUP = UserPreferences();
  cUP.setUserPreferences().then((value) {
    if (value == true) {
      cUP.modifyNotifications(notification: notification);
    }
  });
}

Map<String, dynamic> pushNotificationData = {};
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  await Firebase.initializeApp();
  //message.data.forEach((k, v) => print('$k: $v, ${v.runtimeType}'));
  pushNotificationData = message.data;
  if (message.data?.isNotEmpty == true) {
    saveNotification(message.data);
  }
  //print('Message data payload: ${message.data}');
  //print("Handling a background message: ${message.messageId}");
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
//   FirebaseAppCheck firebaseAppCheck = FirebaseAppCheck.getInstance();
//   firebaseAppCheck.installAppCheckProviderFactory(
//   SafetyNetAppCheckProviderFactory.getInstance());
  await FirebaseAppCheck.instance
      .activate(webRecaptchaSiteKey: '0B89DFBC-CF16-4CFB-AA85-D0106FBB59AD');
  FirebaseAppCheck.instance.app.setAutomaticResourceManagementEnabled(true);
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Create an Android Notification Channel.
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  Future.wait([
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(privacyAndSecurity),
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel),
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(newMessageNotification),
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(productTooOld),
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel),
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalNotificationChannel)
  ]);
  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(defaultChannel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appSettings = AppSettings();

  @override
  void initState() {
    //super.initState();
    try {
      FirebaseMessaging.instance.getToken().then((tokenValue) {
        //print('Token: $tokenValue');
      });
    } catch (e) {}

    AndroidInitializationSettings initialzationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/launcher_icon');
    InitializationSettings initializationSettings =
        InitializationSettings(android: initialzationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      pushNotificationData = message.data;
      if (pushNotificationData?.isNotEmpty == true) {
        saveNotification(pushNotificationData);
      }
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      AndroidNotificationChannel myChannel =
          getAndroidNotificationChannel(android.sound);
      AndroidNotificationDetails androidSpecifics = AndroidNotificationDetails(
          myChannel.id, myChannel.name, myChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'launcher_icon',
          playSound: true,
          enableLights: true,
          sound: myChannel.sound,
          largeIcon: const DrawableResourceAndroidBitmap('launcher_icon'));
      NotificationDetails notificationsAndroidSpecifics =
          NotificationDetails(android: androidSpecifics);
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            notificationsAndroidSpecifics,
            payload: jsonEncode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> notificationData = message?.data;

      if (notificationData?.isNotEmpty == true) {
        int startTab = int.tryParse(notificationData['startTab']);
        saveNotification(notificationData);
        Navigator.push(
            navigatorKey.currentState.context,
            MaterialPageRoute(
                builder: (context) => BottomNavController(startTab: startTab)));
      } else {
        Navigator.push(
            navigatorKey.currentState.context,
            MaterialPageRoute(
                builder: (context) => BottomNavController(startTab: 3)));
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(saveNewDevicesToDatabase);
    super.initState();
  }

  Future<void> saveNewDevicesToDatabase(String token) async {
    UserPreferences usersPreferences = UserPreferences();
    await usersPreferences.setUserPreferences();
    UserModel user = usersPreferences.getCurrentUser();
    if (user != null) {
      String newDeviceIds =
          UserModel.getUpdatedDeviceIds(token, user.deviceIds);
      user.deviceIds = newDeviceIds;
      ApiRequest.updateUserDevices(
          userId: user.user_id, newDeviceToken: newDeviceIds);
      usersPreferences.saveUser(user);
    }
  }

  Future getInitialMessage() async {
    RemoteMessage initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    //print('We got an initial message of ${initialMessage.data}');
    if (initialMessage?.data != null) {
      setState(() {
        pushNotificationData = initialMessage.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettings>.value(
      value: _appSettings,
      child: Consumer<AppSettings>(
        builder: (context, value, child) {
          return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              locale: Locale(
                Provider.of<AppSettings>(context).locale != null
                    ? Provider.of<AppSettings>(context).locale
                    : 'en',
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                fontFamily: 'helvetica',
              ),
              home: SplashScreen(pushNotificationData: pushNotificationData));
        },
      ),
    );
  }
}
