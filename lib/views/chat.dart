import 'dart:ui' as ui;
import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:just_audio/just_audio.dart' as ap;
import 'package:peervendors/Responsive/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:peervendors/helpers/get_images.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/product_details.dart';
import 'package:peervendors/views/record_audio.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'contact_us.dart';

class Chat extends StatefulWidget {
  final String chatRoomId;
  final int otherUsersUserId;
  final String toUserName;
  final String userLang;
  final String fromUserName;
  final UserModel currentUser;
  final bool isCustomerService;
  final UserPreferences cUP;
  List<String> supportIssue;
  final Map<String, dynamic> chatRoomDetails;
  String image;

  Chat(
      {Key key,
      @required this.chatRoomId,
      @required this.otherUsersUserId,
      @required this.toUserName,
      @required this.userLang,
      @required this.fromUserName,
      @required this.isCustomerService,
      @required this.chatRoomDetails,
      @required this.currentUser,
      @required this.cUP,
      this.image,
      this.supportIssue})
      : super(key: key);
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  Stream<QuerySnapshot> chatRoomMessages;
  TextEditingController messageEditingController = TextEditingController();
  bool _hasFirstMessageBeenSent = false;
  bool _shouldShowMediaOptions = true;
  final ImagePicker _imagePicker = ImagePicker();
  final chatMediaRef = FirebaseStorage.instance;
  final FirestoreDB firestoreDB = FirestoreDB();
  final _uuid = const Uuid();
  String s3loadFileName;
  bool isLoading = false;
  Map<String, String> fields;
  int currentNumberOfAudios = 0;
  int permissionsNumber = -1;
  List<int> durationOfAudios = List<int>.generate(20, (i) => 0);
  List<String> pathOfAudios = List<String>.generate(20, (i) => '');
  List<String> messageKeys = [
    'emailMessageTitle',
    'subject',
    'emailMessageBody'
  ];
  String pathOfAudio;
  bool showPlayer = false;
  Color micColor = Colors.white;
  Widget subTitle;

  void setLoadingState(bool status) {
    setState(() {
      isLoading = status;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> showRecordAudioDialog() async {
    bool shouldShowRecordingHelp = false;
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
                title: shouldShowRecordingHelp
                    ? Text(AppLocalizations.of(context)
                        .recordMessage
                        .split('. ')
                        .last)
                    : Text(AppLocalizations.of(context)
                        .recordMessage
                        .split('. ')
                        .first),
                content: SizedBox(
                  height: 90,
                  child: showPlayer
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: AudioPlayer(
                            audioDuration:
                                durationOfAudios[currentNumberOfAudios],
                            audioPlayer: ap.AudioPlayer(),
                            isLocalSource: true,
                            sliderWidth: 200,
                            showDeleteIcon: true,
                            source: pathOfAudio,
                            onDelete: () {
                              pathOfAudio = null;
                              showPlayer = false;
                              setState(() {});
                            },
                          ),
                        )
                      : AudioRecorder(
                          onStop: (path) {
                            ap.AudioPlayer().setFilePath(path).then((duration) {
                              if (duration != null) {
                                setState(() {
                                  durationOfAudios[currentNumberOfAudios] =
                                      duration.inMilliseconds;
                                  pathOfAudio = path;
                                  showPlayer = true;
                                });
                              }
                            });
                          },
                        ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context).send),
                    onPressed: () async {
                      if (pathOfAudio != null) {
                        String uuid = _uuid.v4();
                        dynamic res = await Future.wait([
                          ApiRequest.postAnAudio(
                              fileName: uuid, audioFilePath: pathOfAudio),
                          ap.AudioPlayer().setFilePath(pathOfAudio)
                        ]);
                        if (res != null) {
                          Map<String, dynamic> chatMessageMap = {
                            'sendBy': widget.currentUser.user_id,
                            'message':
                                'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/${res[0]}',
                            'time': DateTime.now().millisecondsSinceEpoch,
                            'duration': res[1].inMilliseconds
                          };
                          firestoreDB.addMessage(
                              widget.chatRoomId, chatMessageMap,
                              isCustomerService: widget.isCustomerService);
                          currentNumberOfAudios++;
                          pathOfAudio = null;
                          showPlayer = false;
                          //print('durationOfAudios $durationOfAudios');
                          setState(() {});
                          Map<String, String> params = {
                            'to_firebase_id':
                                widget.otherUsersUserId.toString(),
                            'title': 'New Voice Message',
                            'user_lang': widget.userLang,
                            'from_name': widget.fromUserName,
                            'message': 'More info about my product',
                            'is_customer_service':
                                '${widget.isCustomerService}',
                            'senders_user_id': '${widget.currentUser.user_id}',
                            'audio':
                                'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/${res[0]}',
                            'senders_profile':
                                '${widget.currentUser.profilePicture}'
                          };
                          if (widget.isCustomerService) {
                            params['to_firebase_id'] =
                                widget.currentUser.user_id.toString();
                            params['addition_info'] =
                                '${widget.otherUsersUserId.toString()}--${widget.chatRoomId}';
                          }
                          await ApiRequest.sendPushNotification(params: params);
                        }
                        Navigator.of(context).pop();
                      } else {
                        shouldShowRecordingHelp = true;
                        setState(() {});
                        Utils.showToast(
                            context,
                            AppLocalizations.of(context).noAudioToSend,
                            Colors.red);
                      }
                    },
                  ),
                ]);
          });
        });
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: chatRoomMessages,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: snapshot.data.docs.length,
                physics: const BouncingScrollPhysics(),
                reverse: true,
                itemBuilder: (context, index) {
                  var indexData =
                      snapshot.data.docs[index].data() as Map<String, dynamic>;
                  int audioDuration = indexData.containsKey('duration')
                      ? snapshot.data.docs[index].get('duration')
                      : -1;
                  return MessageTile(
                      message: indexData['message'],
                      sentByMe:
                          widget.currentUser.user_id == indexData['sendBy'],
                      time: indexData['time'],
                      audioDuration: audioDuration);
                })
            : const Center(child: CircularProgressIndicator());
      },
    );
  }

//this currently work but uploads in gcp which is slow. Working to figure out a way to directly upload to S3.
  pickImageFile(ImageSource source, {String isFirstImage = 'no'}) async {
    List<dynamic> pickedFileDetails = await GetImages.getImageFile(
        _imagePicker, source,
        imageUseFor: 'profile',
        isFirstImage: isFirstImage,
        cropMessage: AppLocalizations.of(context).cropYourImage);
    if (pickedFileDetails != null && pickedFileDetails[1] != null) {
      setLoadingState(true);
      String returned = await ApiRequest.postAnImage(
          imageFilePath: pickedFileDetails[0].path,
          imageType: 'profile',
          fileName: pickedFileDetails[1]);
      if (returned != null) {
        Map<String, dynamic> chatMessageMap = {
          'sendBy': widget.currentUser.user_id,
          'message':
              'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/$returned',
          'time': DateTime.now().millisecondsSinceEpoch
        };
        firestoreDB.addMessage(widget.chatRoomId, chatMessageMap,
            isCustomerService: widget.isCustomerService);

        Map<String, String> params = {
          'to_firebase_id': widget.otherUsersUserId.toString(),
          'title': 'Live Picture of Products',
          'user_lang': widget.userLang,
          'from_name': widget.fromUserName,
          'message': 'Live Picture of Products',
          'is_customer_service': '${widget.isCustomerService}',
          'senders_user_id': '${widget.currentUser.user_id}',
          'image':
              'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/$returned',
          'senders_profile': '${widget.currentUser.profilePicture}'
        };
        if (widget.isCustomerService) {
          params['to_firebase_id'] = widget.otherUsersUserId.toString();
          params['addition_info'] =
              '${widget.otherUsersUserId.toString()}--${widget.chatRoomId}';
        }
        await ApiRequest.sendPushNotification(params: params);
      } else {
        Utils.showToast(
            context, AppLocalizations.of(context).uploadFailed, Colors.red);
      }
      setLoadingState(false);
    } else {
      Utils.showToast(
          context, AppLocalizations.of(context).uploadFailed, Colors.red);
    }
  }

  generateUploadUrl(String extention) async {
    setLoadingState(true);
    String image = _uuid.v4() + extention + '|is_post';
    Map<String, dynamic> res = await ApiRequest.getPresignedUrl(image);
    Map<String, dynamic> lfields = res['fields'];
    if (res != null) {
      await ApiRequest.postAnImageToS3(
          fileName: 'fileName',
          imageFilePath: 'imageFilePath',
          fields: res['fields'],
          url: res['url']);
      Map<String, String> lfields = {};
      res['fields'].forEach((k, v) => lfields.addAll({k: v.toString()}));
      setState(() {
        s3loadFileName = res['url'];
        fields = lfields;
      });
    }
  }

  addMessage() {
    if (messageEditingController.text != null &&
        messageEditingController.text.trim().isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        'sendBy': widget.currentUser.user_id,
        'message': messageEditingController.text,
        'time': DateTime.now().millisecondsSinceEpoch
      };
      firestoreDB.addMessage(widget.chatRoomId, chatMessageMap,
          isCustomerService: widget.isCustomerService);
      if (!_hasFirstMessageBeenSent) {
        Map<String, String> params = {
          'to_firebase_id': widget.otherUsersUserId.toString(),
          'title': 'New Message',
          'user_lang': widget.userLang,
          'from_name': widget.fromUserName,
          'message': messageEditingController.text,
          'is_customer_service': '${widget.isCustomerService}',
          'senders_user_id': '${widget.currentUser.user_id}',
          'senders_profile': '${widget.currentUser.profilePicture}'
        };
        if (widget.isCustomerService) {
          params['to_firebase_id'] = widget.currentUser.user_id.toString();
          params['addition_info'] =
              '${widget.otherUsersUserId.toString()}--${widget.chatRoomId}';
        }
        if (widget.chatRoomDetails.containsKey('lastAdImage')) {
          params['image'] = widget.chatRoomDetails['lastAdImage'];
        }
        ApiRequest.sendPushNotification(params: params);
        setState(() {
          _hasFirstMessageBeenSent = true;
        });
      }
      messageEditingController.text = '';
      _shouldShowMediaOptions = true;
      setState(() {});
    }
  }

  @override
  void initState() {
    firestoreDB
        .getChats(widget.chatRoomId,
            isCustomerService: widget.isCustomerService)
        .then((val) {
      setState(() {
        chatRoomMessages = val;
      });
    });
    super.initState();
  }

  showImagePicker({bool isImage = true}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Colors.black45,
            height: SizeConfig.screenHeight / 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                          pickImageFile(ImageSource.camera);
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
                          pickImageFile(ImageSource.gallery);
                        },
                      ),
                      elevation: 6,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  getAndSaveImage(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.storage].request();
    if (statuses != null) {
      final pg = PermissionStatus.granted;
      if (statuses[Permission.camera] == pg &&
          statuses[Permission.storage] == pg) {
        permissionsNumber = 2;
        showImagePicker();
      } else if (statuses[Permission.camera] == pg) {
        permissionsNumber = 1;
        pickImageFile(ImageSource.camera);
      } else if (statuses[Permission.storage] == pg) {
        permissionsNumber = 0;
        pickImageFile(ImageSource.gallery);
      } else {
        Utils.showFailureDialog(context, "Media");
      }
    } else {
      Utils.showFailureDialog(context, "Media");
    }
  }

  Future showCustomerSupportContacts() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.all(20),
            title: Text(
              AppLocalizations.of(context).needHelp,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            contentPadding: const EdgeInsets.all(0),
            content: Builder(builder: (context) {
              return SizedBox(
                  height: 300,
                  width: SizeConfig.screenWidth,
                  child: Column(children: [
                    const SizedBox(height: 10),

                    Text(AppLocalizations.of(context).contactViaWhatsApp),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    WhatsAppWidget(
                        iconData: FontAwesomeIcons.whatsapp,
                        showMessage: true,
                        isCustomerSupport: true,
                        color: Colors.white,
                        message: AppLocalizations.of(context).talkWithSupport,
                        userId: widget.currentUser.user_id,
                        language: widget.currentUser.user_lang,
                        countryCode: widget.currentUser.country_code),
                    // buildContactSupportButton('+1 (708) 465-0154',
                    //     AppLocalizations.of(context).phoneNumber, Icons.copy),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context).contactViaEmail),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    buildContactSupportButton("support@peervendors.com",
                        AppLocalizations.of(context).email, Icons.copy),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context).chatWithSupport),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    ElevatedButton.icon(
                        style: styleElevatedButton(),
                        onPressed: () async {
                          UserPreferences cUP = UserPreferences();
                          await cUP.setUserPreferences();
                          var currentUser = widget.cUP.getCurrentUser();
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContactUs(
                                      currentUser: currentUser, cUP: cUP)));
                        },
                        icon: const Icon(
                          Icons.chat,
                        ),
                        label:
                            Text(AppLocalizations.of(context).chatWithSupport)),
                    const SizedBox(height: 10),
                  ]));
            }),
            actions: [
              ElevatedButton(
                  style: Utils.roundedButtonStyle(),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).gotIt))
            ],
          );
        });
  }

  Widget buildContactSupportButton(
      String text, String prefix, IconData iconData) {
    return ElevatedButton.icon(
        style: styleElevatedButton(),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: text));
          Utils.showToast(context,
              prefix + ' ' + AppLocalizations.of(context).copied, Colors.green);
        },
        icon: Icon(iconData),
        label: Text(text));
  }

  ButtonStyle styleElevatedButton(
      {Color color = Colors.green, double widthFactor = 0.6}) {
    return ElevatedButton.styleFrom(
        primary: color,
        minimumSize: Size(SizeConfig.screenWidth * widthFactor, 35));
  }

  changeSubTitle() {
    subTitle = Text(widget.chatRoomDetails["lastDescription"],
        overflow: TextOverflow.ellipsis, maxLines: 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (subTitle == null) {
      subTitle = AnimatedTextKit(
        animatedTexts: AppLocalizations.of(context)
            .buyingWarning
            .split(',,')
            .map((e) => FadeAnimatedText(e,
                duration: const Duration(milliseconds: 4000),
                textStyle: TextStyle(fontWeight: FontWeight.bold)))
            .toList(),
        totalRepeatCount: 2,
        onFinished: changeSubTitle,
      );
    }
    return Scaffold(
        backgroundColor: Colors.blue[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Center(
              child: Text(
            widget.toUserName,
          )),
          actions: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: ElevatedButton(
                    style: Utils.roundedButtonStyle(
                        primaryColor: Colors.white, radius: 10),
                    onPressed: showCustomerSupportContacts,
                    child: Text(
                      AppLocalizations.of(context).needHelp,
                      style: TextStyle(color: Colors.blue),
                    )))
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              chatMessages(),
              Container(
                alignment: Alignment.bottomCenter,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.indigoAccent[100],
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20))),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        minLines: 1,
                        maxLines: 7,
                        onChanged: (text) {
                          if (_shouldShowMediaOptions) {
                            setState(() {
                              _shouldShowMediaOptions = false;
                            });
                          }
                        },
                        controller: messageEditingController,
                        style: simpleTextStyle(),
                        decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context).message + ' ...',
                            hintStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            border: InputBorder.none),
                      )),
                      const SizedBox(
                        width: 8,
                      ),
                      isLoading
                          ? const SizedBox(child: CircularProgressIndicator())
                          : const SizedBox(
                              width: 0,
                            ),
                      _shouldShowMediaOptions
                          ? IconButton(
                              onPressed: () {
                                getAndSaveImage(context);
                              },
                              icon: Icon(
                                FontAwesomeIcons.camera,
                                color: micColor,
                                size: 20,
                              ),
                            )
                          : const SizedBox.shrink(),
                      _shouldShowMediaOptions
                          ? IconButton(
                              onPressed: showRecordAudioDialog,
                              icon: Icon(
                                FontAwesomeIcons.microphone,
                                color: micColor,
                              ))
                          : const SizedBox.shrink(),
                      GestureDetector(
                        onTap: addMessage,
                        child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.pink[100]],
                                    begin: FractionalOffset.topLeft,
                                    end: FractionalOffset.bottomRight),
                                borderRadius: BorderRadius.circular(40)),
                            child: const Center(
                                child: Icon(FontAwesomeIcons.paperPlane,
                                    color: Colors.white, size: 20))),
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                height: 75,
                width: SizeConfig.screenWidth,
                child: !widget.chatRoomDetails.containsKey('lastAdImage')
                    ? const SizedBox.shrink()
                    : Card(
                        elevation: 5,
                        color: Colors.white,
                        child: ListTile(
                            horizontalTitleGap: 10,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            onTap: () async {
                              var ad = await ApiRequest.getAd(
                                  widget.chatRoomDetails['lastAdId'],
                                  widget.currentUser.currencySymbol);
                              if (ad != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProductDetails(
                                            adsDetail: ad,
                                            currentUser: widget.currentUser,
                                            cUP: widget.cUP)));
                              } else {
                                Utils.showToast(context,
                                    'This ad is already Sold', Colors.red);
                              }
                            },
                            leading: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                child: Image.network(
                                    'https://pvendors.s3.eu-west-3.amazonaws.com/prod_ad_images/${widget.chatRoomDetails["lastAdImage"]}',
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
                                  '${widget.chatRoomDetails["lastAdPrice"]}  ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(widget.chatRoomDetails["lastAdTitle"],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)
                              ],
                            ),
                            subtitle: subTitle)),
              ),
            ],
          ),
        ));
  }

  Widget buildImage(String image) {
    if (image == null || image.length < 10) {
      return const SizedBox.shrink();
    } else {
      image = image.length > 50
          ? image
          : 'https://pvendors.s3.eu-west-3.amazonaws.com/prod_ad_images/$image';
      return PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          // title: Text(widget.fromUserName),
          // subtitle: Text(widget.fromUserName),
          child: Image.network(image));
    }
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sentByMe;
  final int time;
  final int audioDuration;
  String dateString;

  MessageTile(
      {Key key,
      this.audioDuration,
      @required this.message,
      @required this.sentByMe,
      @required this.time})
      : super(key: key) {
    this.dateString = FirestoreDB().convertTimeStampToDisplayTimeString(time);
  }

  TextStyle textStyle({double fontSize = 16, fontStyle = FontStyle.normal}) {
    return TextStyle(
        color: sentByMe ? Colors.white : Colors.blue[900],
        fontSize: fontSize,
        fontStyle: fontStyle,
        fontFamily: 'OverpassRegular',
        fontWeight: FontWeight.w300);
  }

  playAudioFromUrl(String url, double width, int duration) {
    return Container(
        decoration: sentByMe
            ? const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20)),
                color: Colors.grey)
            : const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                color: Colors.grey),
        width: width,
        child: AudioPlayer(
            audioDuration: audioDuration,
            audioPlayer: ap.AudioPlayer(),
            isLocalSource: false,
            sliderWidth: 225,
            showDeleteIcon: false,
            onDelete: () {},
            source: url));
  }

  Widget buildImage(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(20),
      ),
      child: Image.network(url, height: 300, fit: BoxFit.fitHeight,
          errorBuilder: (context, exception, trace) {
        return Image.asset(
          'assets/images/img_product_placeholder.jpg',
          fit: BoxFit.cover,
        );
      }, loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) {
          return child;
        } else {
          return SizedBox(
              height: 300,
              width: 250,
              child: Center(
                  child: Utils.loadingWidget(
                      AppLocalizations.of(context).loadingImage)));
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMedia = message.startsWith('https://firebasestorage.googleapis') ||
        message.startsWith(
            'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/');
    if (message == "DefaultMessage") {
      return const SizedBox.shrink();
    } else {
      return Container(
        padding: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: sentByMe ? 0 : 10,
            right: sentByMe ? 10 : 0),
        alignment: sentByMe ? Alignment.topRight : Alignment.topLeft,
        child: Container(
            margin: sentByMe
                ? const EdgeInsets.only(left: 30)
                : const EdgeInsets.only(right: 30),
            padding: isMedia
                ? const EdgeInsets.all(3)
                : const EdgeInsets.symmetric(vertical: 9, horizontal: 20),
            decoration: BoxDecoration(
                borderRadius: sentByMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomLeft: Radius.circular(23))
                    : const BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomRight: Radius.circular(23)),
                color: sentByMe ? Colors.blue[700] : Colors.white),
            child: Column(children: [
              Text(dateString,
                  style: textStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  )),
              isMedia
                  ? RegExp(r"[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.jpg")
                          .hasMatch(message)
                      ? buildImage(message)
                      : playAudioFromUrl(message,
                          MediaQuery.of(context).size.width / 2, audioDuration)
                  : Text(message, style: textStyle())
            ])),
      );
    }
  }
}
