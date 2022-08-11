import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peervendors/helpers/play_videos.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/helpers/get_images.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

class SelectImagesForAnAd extends StatefulWidget {
  final String categoryId;
  final String subCategoryId;
  final String title;
  final String description;
  final String price;
  final Map<String, dynamic> currentUsersAddress;
  final int userId;
  final String userLang;
  final String pickUpLocation;
  final int advertisementIndex;
  final String sellerPhoneNumber;
  bool isLoading = false;

  SelectImagesForAnAd(
      {Key key,
      @required this.categoryId,
      @required this.subCategoryId,
      @required this.title,
      @required this.currentUsersAddress,
      @required this.userId,
      @required this.userLang,
      @required this.description,
      @required this.price,
      @required this.pickUpLocation,
      @required this.advertisementIndex,
      @required this.sellerPhoneNumber})
      : super(key: key);

  @override
  _ChooseMultipleImageState createState() => _ChooseMultipleImageState();
}

class _ChooseMultipleImageState extends State<SelectImagesForAnAd> {
  int permissionsNumber = -1;
  List<String> fileNamesInBackEnd = [];
  List<File> selectedImages = [];
  bool isLoading = false;
  String isThisFirstImage = 'yes';
  final ImagePicker _imagePicker = ImagePicker();
  final Reference ref = FirebaseStorage.instance.ref('ads');
  final Utils utils = Utils();
  final _uuid = Uuid();
  String loadingMessage = '';
  final imageExtentions = ['png', 'jpg', 'jpeg'];
  double opacity = 0;

  VideoPlayerController _videoController;
  VideoPlayerController _adVideoController;

  @override
  void initState() {
    super.initState();
  }

  void setLoadingState(bool status) {
    setState(() {
      isLoading = status;
    });
  }

  pickImageFile(ImageSource source, {String isFirstImage = 'no'}) async {
    List<String> files;
    if (source == ImageSource.camera) {
      try {
        files = await GetImages.pickImageWithoutCropping(_imagePicker, source);
        await addImages(files);
      } catch (e) {}
    } else {
      files = await GetImages.pickMultipleImages(_imagePicker);
      await addImages(files);
    }
  }

  Future cropAndPostImage(
    String filePath,
  ) async {
    if (filePath != null) {
      var t = await GetImages.cropImage(File(filePath), _uuid.v4(),
          cropMessage: AppLocalizations.of(context).cropYourImage);
      if (t != null) {
        await updateFiles(t[0].path, t[1]);
      } else {
        await updateFiles(filePath, _uuid.v4());
      }
    }
  }

  Future pickVideo(ImageSource source) async {
    String pickedVideo = await GetImages.pickVideo(source, permissionsNumber);
    if (pickedVideo != null) {
      await updateFiles(pickedVideo, _uuid.v4(), isVideo: true);
    } else {
      Utils.showToast(
          context, AppLocalizations.of(context).uploadFailed, Colors.red);
    }
  }

  Future addImages(List<String> paths) async {
    loadingMessage = AppLocalizations.of(context).savingImage;
    if (paths != null) {
      for (String path in paths) {
        if (path != null) {
          await ask2Crop(path);
        }
      }
    }
    setState(() {});
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
                          isImage
                              ? pickImageFile(ImageSource.camera,
                                  isFirstImage: isThisFirstImage)
                              : pickVideo(ImageSource.camera);
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
                          isImage
                              ? pickImageFile(ImageSource.gallery,
                                  isFirstImage: isThisFirstImage)
                              : pickVideo(ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).chooseImage),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: !isLoading
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Text(
                      AppLocalizations.of(context)
                          .add1OrMorePictures
                          .split('  ')
                          .first,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    )),
                    Utils.buildPageSummary(AppLocalizations.of(context)
                        .add1OrMorePictures
                        .split('  ')
                        .last),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.play_circle_fill_outlined,
                              color: Colors.red,
                            ),
                            onPressed: playVideo,
                            label: Text(
                              AppLocalizations.of(context).needHelp,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          fileNamesInBackEnd.length <= 8 &&
                                  (fileNamesInBackEnd.isEmpty ||
                                      fileNamesInBackEnd.any((f) =>
                                          !imageExtentions.contains(
                                              f.split('.').last.toLowerCase())))
                              ? const SizedBox.shrink()
                              : OutlinedButton.icon(
                                  icon: Container(
                                      //color: Colors.green,
                                      decoration: Utils.containerBoxDecoration(
                                          color: Colors.green),
                                      child: const Icon(
                                        Icons.add_circle_outline_outlined,
                                        color: Colors.white,
                                      )),
                                  onPressed: addVideo,
                                  label: Text(
                                    "Video < 6 MB",
                                    //AppLocalizations.of(context).addVideo,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                )
                        ]),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                          itemCount: selectedImages.length + 1,
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, childAspectRatio: 0.9),
                          itemBuilder: (_, index) {
                            String f = selectedImages.isEmpty || index == 0
                                ? ""
                                : selectedImages[index - 1].path;
                            bool isImageFile = imageExtentions
                                .contains(f.split('.').last.toLowerCase());
                            bool isProfileImage = index > 0 &&
                                isImageFile &&
                                fileNamesInBackEnd[index - 1] ==
                                    fileNamesInBackEnd.firstWhere((e) =>
                                        imageExtentions.contains(
                                            e.split('.').last.toLowerCase()));
                            return index == 0
                                ? Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      GestureDetector(
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(12)),
                                                boxShadow: [
                                                  utils.boxShadows()[0]
                                                ]),
                                            child: Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                              size:
                                                  SizeConfig.screenWidth * 0.12,
                                            )),
                                        onTap: () async {
                                          if (_videoController != null &&
                                              _videoController
                                                  .value.isInitialized) {
                                            _videoController.pause();
                                          }
                                          if (permissionsNumber == -1) {
                                            Map<Permission, PermissionStatus>
                                                statuses = await [
                                              Permission.camera,
                                              Permission.storage
                                            ].request();
                                            if (statuses != null) {
                                              PermissionStatus pg =
                                                  PermissionStatus.granted;
                                              if (statuses[Permission.camera] ==
                                                      pg &&
                                                  statuses[
                                                          Permission.storage] ==
                                                      pg) {
                                                permissionsNumber = 2;
                                                showImagePicker();
                                              } else if (statuses[
                                                      Permission.camera] ==
                                                  pg) {
                                                permissionsNumber = 1;
                                                pickImageFile(
                                                    ImageSource.camera,
                                                    isFirstImage:
                                                        isThisFirstImage);
                                              } else {
                                                permissionsNumber = 0;
                                                pickImageFile(
                                                    ImageSource.gallery,
                                                    isFirstImage:
                                                        isThisFirstImage);
                                              }
                                            }
                                          } else {
                                            if (selectedImages.length > 7) {
                                              Utils.showToast(
                                                  context,
                                                  AppLocalizations.of(context)
                                                      .max8Images,
                                                  Colors.red);
                                            } else {
                                              permissionsNumber == 2
                                                  ? showImagePicker()
                                                  : permissionsNumber == 1
                                                      ? pickImageFile(
                                                          ImageSource.camera,
                                                          isFirstImage:
                                                              isThisFirstImage)
                                                      : pickImageFile(
                                                          ImageSource.gallery,
                                                          isFirstImage:
                                                              isThisFirstImage);
                                            }
                                          }
                                        },
                                      ),
                                    ]),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(1),
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      !isImageFile
                                          ? AspectRatio(
                                              aspectRatio: _adVideoController
                                                  .value.aspectRatio,
                                              child: Stack(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                children: <Widget>[
                                                  VideoPlayer(
                                                      _adVideoController),
                                                  ControlsOverlay(
                                                    controller:
                                                        _adVideoController,
                                                    canShowPlayback: false,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  Utils.borderRadius(),
                                              child: Image.file(
                                                  selectedImages[index - 1],
                                                  fit: BoxFit.fill),
                                            ),
                                      Positioned(
                                        right: -1,
                                        top: -1,
                                        child: Container(
                                            height: 25,
                                            width: 25,
                                            //color: Colors.blue[100],
                                            decoration:
                                                Utils.containerBoxDecoration(
                                                    radius: 8,
                                                    color: Colors.blue[100]),
                                            child: IconButton(
                                                padding:
                                                    const EdgeInsets.all(3.0),
                                                icon: const Icon(
                                                  Icons.delete_forever_outlined,
                                                  color: Colors.red,
                                                  size: 17,
                                                ),
                                                onPressed: () {
                                                  ApiRequest.deleteAnImage(
                                                      fileName:
                                                          fileNamesInBackEnd[
                                                              index - 1]);
                                                  selectedImages
                                                      .removeAt(index - 1);
                                                  fileNamesInBackEnd
                                                      .removeAt(index - 1);
                                                  setState(() {});
                                                })),
                                      ),
                                      Positioned(
                                        left: -10,
                                        top: -10,
                                        child: isProfileImage
                                            ? TextButton.icon(
                                                style: Utils.roundedButtonStyle(
                                                    radius: 2,
                                                    primaryColor:
                                                        Colors.blue[100],
                                                    minSize: Size(65, 25)),
                                                label: Text(
                                                  'Profile',
                                                  style: TextStyle(
                                                      color: Colors.blue[900]),
                                                ),
                                                icon: Icon(
                                                  Icons.star,
                                                  color: Colors.blue[900],
                                                  size: 17,
                                                ),
                                                onPressed: () {})
                                            : const SizedBox.shrink(),
                                      )
                                    ]));
                          }),
                    ),
                    Center(
                        child: ElevatedButton(
                            style: Utils.roundedButtonStyle(
                                minSize: Size(200, 38)),
                            child: Text(AppLocalizations.of(context).submit),
                            onPressed: () {
                              bool hasPhoto = fileNamesInBackEnd.any((f) =>
                                  imageExtentions.contains(
                                      f.split('.').last.toLowerCase()));
                              if (fileNamesInBackEnd.isEmpty || !hasPhoto) {
                                Utils.showToast(
                                    context,
                                    AppLocalizations.of(context)
                                        .add1OrMorePictures
                                        .split('.')
                                        .first,
                                    colorError);
                              } else {
                                loadingMessage = AppLocalizations.of(context)
                                    .loadingPleaseWait;
                                createNewAd(context);
                              }
                            })),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(child: Utils.loadingWidget(loadingMessage)),
    );
  }

  addVideo() async {
    if (permissionsNumber == 2) {
      showImagePicker(isImage: false);
    } else if (permissionsNumber == 1) {
      pickVideo(ImageSource.gallery);
    } else {
      pickVideo(ImageSource.camera);
    }
  }

  createNewAd(BuildContext context) async {
    setLoadingState(true);
    Map<String, String> data = {
      'lat': widget.currentUsersAddress['lat'].toString(),
      'lng': widget.currentUsersAddress['lng'].toString(),
      'country_code': widget.currentUsersAddress['country_code'],
      'address_id': widget.currentUsersAddress['address_id'].toString(),
      'seller_id': widget.userId.toString(),
      'price': widget.price,
      'seller_lang': widget.userLang,
      'seller_phone': widget.sellerPhoneNumber,
      'item_name': widget.title,
      'item_description': widget.description,
      'category_id': widget.categoryId,
      'sub_category_id': widget.subCategoryId,
      'images': fileNamesInBackEnd.join('|'),
      'pick_up_location': widget.pickUpLocation,
      "advertisement_index": widget.advertisementIndex.toString(),
      "state": widget.currentUsersAddress['state']
    };
    ApiRequest.createAd(params: data).then((value) {
      setLoadingState(false);
      if (value == true) {
        if (widget.sellerPhoneNumber.endsWith('0000000000')) {
          Utils.setDialog(context,
              title: AppLocalizations.of(context).adCreated,
              barrierDismissible: false,
              children: [
                Text(AppLocalizations.of(context).request2addPhone),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context).how2AddPhone),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context).want2UpdatePhoneNow),
              ],
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      returnHome(4, context, intend2editProfile: true);
                    },
                    child: Text(AppLocalizations.of(context).yes)),
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      returnHome(0, context);
                    },
                    child: Text(AppLocalizations.of(context).no))
              ]);
        } else {
          Utils.showToast(context, AppLocalizations.of(context).uploadSuccess,
              Colors.green);
          returnHome(0, context);
        }
      }
    });
  }

  returnHome(int startTab, BuildContext context,
      {bool intend2editProfile = false}) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => BottomNavController(startTab: startTab)));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _adVideoController?.dispose();
    super.dispose();
  }

  Future<bool> initializeVideo() async {
    setLoadingState(true);
    if (_videoController == null || !_videoController.value.isInitialized) {
      String languageCode = Localizations.localeOf(context).languageCode;
      String videoUrl = Utils.getVideoUrl('resizeImages', languageCode);
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController.initialize();
      // Use the controller to loop the video
      _videoController.setLooping(true);
    }
    setLoadingState(false);
    return false;
  }

  Future ask2Crop(String file) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
          contentPadding: const EdgeInsets.only(left: 2, right: 2),
          titlePadding: const EdgeInsets.all(5),
          title: Column(children: [
            Text(AppLocalizations.of(context).want2Crop,
                textAlign: TextAlign.center),
            Utils.buildSeparator(300)
          ]),
          content: ClipRRect(
              borderRadius: Utils.borderRadius(radius: 30),
              child:
                  Image.file(File(file), height: 250, fit: BoxFit.fitHeight)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                updateFiles(file, _uuid.v4());
              },
              child: Text(AppLocalizations.of(context).no,
                  style: const TextStyle(color: Colors.blue)),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    cropAndPostImage(file).onError(
                        (error, stackTrace) => updateFiles(file, _uuid.v4()));
                  } catch (e) {
                    updateFiles(file, _uuid.v4());
                  }
                },
                child: Text(AppLocalizations.of(context).yes,
                    style: const TextStyle(color: Colors.blue)))
          ]),
    );
  }

  Future updateFiles(String path, String fileName,
      {bool isVideo = false}) async {
    if (isVideo) {
      File t = File(path);
      // int l = t.lengthSync();
      String returned =
          await ApiRequest.postAnAudio(fileName: fileName, audioFilePath: path);
      if (returned != null) {
        _adVideoController = VideoPlayerController.file(t);
        await _adVideoController.initialize();
        _adVideoController.setLooping(true);

        selectedImages.add(t);
        fileNamesInBackEnd.add(returned);
      }
    } else {
      String returned = await ApiRequest.postAnImage(
          imageFilePath: path,
          imageType: 'ad',
          isFirstImage: isThisFirstImage,
          fileName: fileName);

      if (returned != null) {
        File f = File(path);
        selectedImages.add(f);
        fileNamesInBackEnd.add(returned);
        isThisFirstImage = 'no';
        opacity = 1;
      } else {
        Utils.showToast(
            context, AppLocalizations.of(context).uploadFailed, Colors.red);
      }
    }
    setState(() {});
  }

  Future playVideo() async {
    await initializeVideo();
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
              VideoProgressIndicator(_videoController, allowScrubbing: true),
            ],
          ),
        ),
      ),
    );
  }
}
