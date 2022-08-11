import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/HomeScreen/Nav_Bar_Pages/home_screen.dart';
import 'package:peervendors/HomeScreen/Nav_Bar_Pages/myads_screen.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/play_videos.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:peervendors/models/customer_info.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/send_email.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/add_review.dart';
import 'package:peervendors/views/buying_details.dart';
import 'package:peervendors/views/chat.dart';
import 'package:peervendors/HomeScreen/Sell/upload_form.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class ProductDetails extends StatefulWidget {
  final AdsDetail adsDetail;
  final ProductListForHomePage currentHomePageAds;
  final Map<String, dynamic> currentAddress;
  final UserPreferences cUP;
  final UserModel currentUser;

  ProductDetails(
      {Key key,
      @required this.adsDetail,
      @required this.cUP,
      @required this.currentUser,
      this.currentHomePageAds,
      this.currentAddress})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MyProductDetails();
}

class MyProductDetails extends State<ProductDetails> {
  final firestoreDb = FirestoreDB();
  final exts = ['png', 'jpg', 'jpeg'];
  bool isLoading = true;
  bool currentUserIsAdSeller = false;
  bool isDownloading = false;
  int currentPageIndex = 1;
  UserModel currentUser;

  AdsDetail currentAd;
  UserPreferences cUP = UserPreferences();
  Color color = Colors.blue;
  List<String> viewedAds;
  List<String> reviewedAds;
  List<String> likedAds;
  String adVideo = '';
  VideoPlayerController _videoController;
  int videoDuration = 4000;
  int intervalDuration = 4000;
  bool haveHomePageAdsChanged = false;
  bool isCheckingFirestore = false;
  ProductListForHomePage similarAds;

  bool itemCanBeDelivered = false;

  @override
  void initState() {
    currentAd = widget.adsDetail;
    num n = num.tryParse(
            currentAd.price.split(' ').last.replaceAll(',', '').trim()) ??
        0.00;
    itemCanBeDelivered = n > 0;
    super.initState();
    setUserPrefs();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  setUserPrefs() async {
    cUP = widget.cUP;
    currentUser = widget.currentUser;
    adVideo = currentAd.images
        .firstWhere((e) => !exts.contains(e.split('.').last), orElse: () => '');

    currentUserIsAdSeller = currentAd.seller_id == currentUser.user_id;
    if (!currentUserIsAdSeller) {
      viewedAds = cUP.getLikedReviewedOrViewedAds(
          viewsOrLikesOrReviews: Constants.peerVendorsViews);
      likedAds = cUP.getLikedReviewedOrViewedAds(
          viewsOrLikesOrReviews: Constants.peerVendorsFavorits);
      if (viewedAds != null) {
        if (!viewedAds.contains('${currentAd.ad_id}')) {
          ApiRequest.likeOrViewAd(currentAd.ad_id,
              viewedOrLikedBy: currentUser.user_id,
              whatToUpdate: 'number_of_views');
          setState(() {
            viewedAds.add('${currentAd.ad_id}');
            currentAd.numberOfViews++;
          });
          if (viewedAds.length > 100) {
            viewedAds = viewedAds.sublist(40);
          }
          cUP.saveString(Constants.peerVendorsViews, viewedAds.join(','));
        }
      } else {
        cUP.saveString(Constants.peerVendorsViews, '${currentAd.ad_id}');
      }
      if (likedAds != null && likedAds.contains('${currentAd.ad_id}')) {
        setState(() {
          color = Colors.red;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
    if (adVideo.isNotEmpty) {
      _videoController =
          VideoPlayerController.network(Constants.imageBaseUrl + adVideo);
      await _videoController.initialize();
      videoDuration = _videoController.value.duration.inMilliseconds;
    }
    setState(() {});
    if (!currentUserIsAdSeller &&
        widget.currentHomePageAds != null &&
        widget.currentHomePageAds.ads_details.length < 150) {
      var ids =
          widget.currentHomePageAds.ads_details.map((e) => e.ad_id).toList();
      int m = ids.reduce(max);
      Map<String, String> params = {"start_ad_id": "$m"};
      currentAd.toJson().forEach((key, value) {
        params[key] = '$value';
      });
      widget.currentAddress.forEach((key, value) {
        params[key] = '$value';
      });
      params.removeWhere((key, value) =>
          'item_description images is_active create_date numberOfLikes numberOfViews price'
              .split(' ')
              .contains(key));
      params['sub_category_id'] = '${currentAd.subCategoryId}';
      similarAds = await ApiRequest.getSimilarAdsTo(currentUser.currencySymbol,
          params: params);

      if (similarAds != null && similarAds.ads_details.isNotEmpty) {
        widget.currentHomePageAds.addNewAds(similarAds);

        if (ids.length != widget.currentHomePageAds.ads_details.length) {
          await cUP.saveHomePageAds(homePageAds: widget.currentHomePageAds);
          await cUP.setTimeWhenEventHappened(
              eventName: Constants.whenHomePageAdsWereExtracted);
          haveHomePageAdsChanged = true;
          filterSimilarAds();
        }
      } else {
        filterSimilarAds();
      }
      if (similarAds == null || similarAds.ads_details.length < 5) {
        Map<String, dynamic> searchInfo = {
          'categoryId': currentAd.category_id,
          'subCategoryId': currentAd.subCategoryId,
          'firebaseId': currentUser.firebaseUserId,
          'lastSearch': DateTime.now().millisecondsSinceEpoch,
          'userId': currentUser.user_id,
          'nOfSimilarAds':
              similarAds == null ? 0 : similarAds.ads_details.length,
          'maxAdId': m,
          'lat': widget.currentAddress['lat'],
          'lng': widget.currentAddress['lng']
        };
        firestoreDb.addSearch(
            newCategoryData: searchInfo,
            userId: currentUser.user_id.toString());
      }
    } else if (!currentUserIsAdSeller &&
        widget.currentHomePageAds != null &&
        widget.currentHomePageAds.ads_details.length > 6) {
      filterSimilarAds();
    }
  }

  void filterSimilarAds() {
    final newAds = widget.currentHomePageAds.ads_details
        .where((ad) => ad.category_id == currentAd.category_id)
        .toList();

    if (newAds.isNotEmpty) {
      similarAds = ProductListForHomePage(ads_details: newAds);
      setState(() {});
    }
  }

  Widget buildImage(String image) {
    if (exts.contains(image.split('.').last)) {
      return ClipRRect(
          borderRadius: Utils.borderRadius(),
          child: Image.network(
            '${Constants.imageBaseUrl}${image}',
            errorBuilder: (context, exception, stack) {
              return Image.asset(
                'assets/images/img_product_placeholder_slider.jpg',
                fit: BoxFit.cover,
              );
            },
          ));
    } else {
      return AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VideoPlayer(_videoController),
            ClosedCaption(text: _videoController.value.caption.text),
            ControlsOverlay(
                controller: _videoController, canShowPlayback: false),
            VideoProgressIndicator(_videoController, allowScrubbing: true),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showSimilarAds =
        similarAds != null && similarAds.ads_details.isNotEmpty;
    return SafeArea(
        child: Scaffold(
            backgroundColor: colorGrey50,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.blue,
              title: Text(AppLocalizations.of(context).productDetails),
              leading: IconButton(
                color: colorWhite,
                icon: Icon(
                    Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back),
                onPressed: () {
                  if (haveHomePageAdsChanged) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (c) => HomeScreen(
                                cUP: cUP,
                                currentUser: currentUser,
                                homePageProducts: widget.currentHomePageAds)),
                        (route) => false);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: isLoading
                ? Utils.loadingWidget(
                    AppLocalizations.of(context).loadingPleaseWait)
                : currentAd != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                children: [
                                  Container(
                                    color: Colors.blue[100],
                                    height: 350,
                                    width: SizeConfig.screenWidth,
                                    child: Center(
                                      child: Stack(
                                        children: [
                                          CarouselSlider(
                                            options: CarouselOptions(
                                              onPageChanged: (s, t) {
                                                if (adVideo.isNotEmpty) {
                                                  intervalDuration = currentAd
                                                              .images[s] ==
                                                          adVideo
                                                      ? max(videoDuration, 4000)
                                                      : 4000;
                                                  setState(() {});
                                                }
                                              },
                                              viewportFraction: 0.9,
                                              autoPlay: true,
                                              aspectRatio: 1.0,
                                              enlargeCenterPage: true,
                                              autoPlayInterval: Duration(
                                                  milliseconds:
                                                      intervalDuration),
                                            ),
                                            items: [
                                              for (var i = 0;
                                                  i < currentAd.images.length;
                                                  i++)
                                                buildImage(currentAd.images[i])
                                            ],
                                          ),
                                          Positioned(
                                              top: 0,
                                              right: 0,
                                              child: currentUser.user_id ==
                                                      currentAd.seller_id
                                                  ? const SizedBox.shrink()
                                                  : Container(
                                                      decoration: Utils
                                                          .containerBoxDecoration(
                                                              radius: 90,
                                                              borderWidth: 2),
                                                      child: IconButton(
                                                        iconSize: 35,
                                                        icon: Icon(
                                                            Icons.favorite,
                                                            color: color),
                                                        onPressed: () {
                                                          if (likedAds !=
                                                              null) {
                                                            setState(() {
                                                              color =
                                                                  Colors.red;
                                                            });
                                                            if (!likedAds.contains(
                                                                '${currentAd.ad_id}')) {
                                                              if (likedAds
                                                                      .length >
                                                                  50) {
                                                                likedAds =
                                                                    likedAds
                                                                        .sublist(
                                                                            20);
                                                              }
                                                              setState(() {
                                                                currentAd
                                                                    .numberOfLikes++;
                                                              });
                                                              likedAds.add(
                                                                  '${currentAd.ad_id}');
                                                              ApiRequest.likeOrViewAd(
                                                                  currentAd
                                                                      .ad_id,
                                                                  whatToUpdate:
                                                                      'number_of_likes',
                                                                  viewedOrLikedBy:
                                                                      currentUser
                                                                          .user_id);
                                                              String myFavs =
                                                                  likedAds.join(
                                                                      ',');
                                                              cUP.saveString(
                                                                  Constants
                                                                      .peerVendorsFavorits,
                                                                  myFavs);
                                                            }
                                                          } else {
                                                            setState(() {
                                                              color =
                                                                  Colors.red;
                                                              likedAds = [
                                                                '${currentAd.ad_id}'
                                                              ];
                                                              currentAd
                                                                  .numberOfLikes++;
                                                            });
                                                            ApiRequest.likeOrViewAd(
                                                                currentAd.ad_id,
                                                                whatToUpdate:
                                                                    'number_of_likes',
                                                                viewedOrLikedBy:
                                                                    currentUser
                                                                        .user_id);
                                                            cUP.saveString(
                                                                Constants
                                                                    .peerVendorsFavorits,
                                                                '${currentAd.ad_id}');
                                                          }
                                                        },
                                                      ))),
                                          Positioned(
                                              top: 0,
                                              right: currentUser.user_id ==
                                                      currentAd.seller_id
                                                  ? 0
                                                  : 55,
                                              child: Container(
                                                decoration: Utils
                                                    .containerBoxDecoration(
                                                        borderWidth: 2,
                                                        radius: 90),
                                                child: isDownloading
                                                    ? const SizedBox(
                                                        height: 50,
                                                        width: 50,
                                                        child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                          color: Colors.blue,
                                                        )))
                                                    : IconButton(
                                                        iconSize: 35,
                                                        icon: const Icon(
                                                            Icons.share_rounded,
                                                            color: Colors.blue),
                                                        onPressed: () async {
                                                          setState(() {
                                                            isDownloading =
                                                                true;
                                                          });
                                                          final imageUrl = Constants
                                                                  .imageBaseUrl +
                                                              currentAd
                                                                  .images[0];
                                                          final url = Uri.parse(
                                                              imageUrl);
                                                          final tempPath =
                                                              await getTemporaryDirectory();
                                                          final path = tempPath
                                                                  .path +
                                                              currentAd
                                                                  .images[0];
                                                          final response =
                                                              await ApiRequest
                                                                      .https()
                                                                  .get(url);
                                                          bool t = response
                                                                  ?.statusCode ==
                                                              200;
                                                          Map<String, String>
                                                              params = {
                                                            "tokens":
                                                                currentUser
                                                                    .deviceIds,
                                                            "image": currentAd
                                                                .images[0],
                                                            "sharer_name":
                                                                currentUser
                                                                    .username,
                                                            "lang": currentUser
                                                                .user_lang,
                                                            "sharer_user_id":
                                                                currentUser
                                                                    .user_id
                                                                    .toString(),
                                                            "message":
                                                                "${currentAd.item_name} ${currentAd.price}",
                                                            "ad_id": currentAd
                                                                .ad_id
                                                                .toString(),
                                                            "seller_id":
                                                                currentAd
                                                                    .seller_id
                                                                    .toString(),
                                                            "contry_code":
                                                                currentUser
                                                                    .country_code,
                                                            "was_file_downloaded":
                                                                t.toString()
                                                          };
                                                          ApiRequest
                                                              .sendSharedAppreciation(
                                                                  params:
                                                                      params);
                                                          if (t == true) {
                                                            File(path).writeAsBytes(
                                                                response
                                                                    .bodyBytes);
                                                            await Share
                                                                .shareFiles([
                                                              path
                                                            ], text: "${currentAd.item_name} ${currentAd.price}.\n\n https://play.google.com/store/apps/details?id=com.peervendors");
                                                          } else {
                                                            Share.share(
                                                                '${currentAd.item_name} ${currentAd.price} \n\nPeer Vendors \n\nhttps://peervendors.com/view_shared_ad/${currentAd.ad_id}/${currentAd.images[0]}--${currentUser.user_lang}-${currentUser.user_id}-${currentAd.seller_id}-${currentUser.country_code}',
                                                                subject: widget
                                                                        .adsDetail
                                                                        .item_name +
                                                                    " - Peer Vendors");
                                                          }

                                                          setState(() {
                                                            isDownloading =
                                                                false;
                                                          });
                                                        }),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Card(
                                    margin: const EdgeInsets.all(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        children: [
                                          !currentUserIsAdSeller &&
                                                  itemCanBeDelivered
                                              ? Column(
                                                  children: [
                                                    isCheckingFirestore
                                                        ? const CircularProgressIndicator()
                                                        : ElevatedButton.icon(
                                                            label: Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .buyItem),
                                                            icon: Icon(
                                                                FontAwesomeIcons
                                                                    .shoppingCart),
                                                            onPressed:
                                                                () async {
                                                              isCheckingFirestore =
                                                                  true;
                                                              setState(() {});
                                                              QuerySnapshot<
                                                                      Object>
                                                                  querySnapshot =
                                                                  await firestoreDb.getOrders(
                                                                      currentAd
                                                                          .ad_id
                                                                          .toString(),
                                                                      currentUser
                                                                          .user_id
                                                                          .toString());

                                                              isCheckingFirestore =
                                                                  false;
                                                              setState(() {});
                                                              if (querySnapshot
                                                                  .docs
                                                                  .isEmpty) {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) => BuyingPage(
                                                                            currentUser: widget
                                                                                .currentUser,
                                                                            cUP: widget
                                                                                .cUP,
                                                                            intendToAddPhone: currentUser.phoneNumber?.endsWith('000000000') ==
                                                                                true,
                                                                            adsDetail:
                                                                                widget.adsDetail)));
                                                              } else {
                                                                final order = querySnapshot
                                                                        .docs[0]
                                                                        .data()
                                                                    as Map<
                                                                        String,
                                                                        dynamic>;
                                                                var createDate = DateFormat(
                                                                        'MMMM dd, yyyy')
                                                                    .format(DateTime.fromMillisecondsSinceEpoch(
                                                                        int.parse(order['orderDateTime']) ??
                                                                            0));
                                                                Utils.setDialog(
                                                                    context,
                                                                    title: AppLocalizations.of(
                                                                            context)
                                                                        .youHaveAlreadyOrdered,
                                                                    children: [
                                                                      Text(
                                                                          "Order Id : ${order['orderId']}",
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 17)),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      Text(
                                                                          "Created On : $createDate",
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 17)),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      Text(
                                                                          "Status: " +
                                                                              order[
                                                                                  'orderStatus'],
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 17)),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      Text(AppLocalizations.of(
                                                                              context)
                                                                          .leaveAShortMessage),
                                                                    ],
                                                                    actions: [
                                                                      ElevatedButton(
                                                                        child: Text(
                                                                            AppLocalizations.of(context).yes),
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                          initiateChat();
                                                                        },
                                                                      ),
                                                                      ElevatedButton(
                                                                        child: Text(
                                                                            AppLocalizations.of(context).no),
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        },
                                                                      )
                                                                    ]);
                                                              }
                                                            }),

                                                    Text(
                                                      "✳ " +
                                                          AppLocalizations.of(
                                                                  context)
                                                              .paymentNote,
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                    // Utils.buildSeparator(
                                                    //     SizeConfig.screenWidth)
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 20, bottom: 8.0, left: 6),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '${currentAd.item_name}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.location_on_outlined,
                                                  color: Colors.red,
                                                  size: 20),
                                              Text(
                                                '${currentAd.pickUpLocation}',
                                                style: Utils.addressStyle(
                                                    color: Colors.black,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0, left: 6),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .description,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: colorBlack,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )),
                                          Container(
                                              height: 2, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0, left: 6),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '${currentAd.item_description}',
                                                  softWrap: true,
                                                  textAlign: TextAlign.start,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: colorBlackDark),
                                                ),
                                              )),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Container(
                                                height: 2, color: Colors.grey),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)
                                                .additionalInfos,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: colorBlack,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .price,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: colorBlack),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  '${currentAd.price}',
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                  style: const TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontSize: 13,
                                                      color: colorBlackDark,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)
                                                      .createDate,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: colorBlack),
                                                ),
                                                Text('${currentAd.createDate}'),
                                              ]),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .likes,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: colorBlack),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 13),
                                                    children: [
                                                      const WidgetSpan(
                                                          child: Icon(
                                                              Icons.favorite,
                                                              color:
                                                                  Colors.red)),
                                                      TextSpan(
                                                          text:
                                                              ' (${currentAd.numberOfLikes})',
                                                          style: const TextStyle(
                                                              color:
                                                                  colorGrey600)),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.end,
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .views,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: colorBlack),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 13),
                                                    children: [
                                                      const WidgetSpan(
                                                          child: Icon(
                                                              Icons
                                                                  .remove_red_eye_outlined,
                                                              color:
                                                                  Colors.red)),
                                                      TextSpan(
                                                          text:
                                                              ' (${currentAd.numberOfViews})',
                                                          style: const TextStyle(
                                                              color:
                                                                  colorGrey600)),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.end,
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .reviews,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: colorBlack),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                        color: colorBlackDark,
                                                        fontSize: 13),
                                                    children: [
                                                      WidgetSpan(
                                                          child:
                                                              SmoothStarRating(
                                                        rating: currentAd
                                                            .averageReview,
                                                        size: 20,
                                                        isReadOnly: true,
                                                      )),
                                                      TextSpan(
                                                          text:
                                                              ' ${currentAd.averageReview.toStringAsFixed(1)}/5.0',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      TextSpan(
                                                          text:
                                                              ' (${currentAd.numberOfReviews})',
                                                          style: const TextStyle(
                                                              color:
                                                                  colorGrey600)),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.end,
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .fullName,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: colorBlack),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                  child: Text(
                                                      '${currentAd.sellerName}',
                                                      textAlign: TextAlign.end,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight
                                                              .bold))),
                                            ],
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                                style: Utils.roundedButtonStyle(
                                                    primaryColor: Colors.blue),
                                                child: currentUserIsAdSeller
                                                    ? Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .markAsSold,
                                                        style:
                                                            const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18))
                                                    : Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .writeAReview,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18)),
                                                onPressed: () {
                                                  if (!currentUserIsAdSeller) {
                                                    List<String> reviewedAds = cUP
                                                        .getLikedReviewedOrViewedAds(
                                                            viewsOrLikesOrReviews:
                                                                Constants
                                                                    .peerVendorsReviews);
                                                    if (reviewedAds == null) {
                                                      cUP.saveString(
                                                          Constants
                                                              .peerVendorsReviews,
                                                          currentAd.ad_id
                                                              .toString());
                                                      goToReviewPage(null);
                                                    } else if (reviewedAds.contains(
                                                        '${currentAd.ad_id}')) {
                                                      setState(() {
                                                        isLoading = true;
                                                      });
                                                      ApiRequest
                                                              .checkUserHasReviewed(
                                                                  currentUser
                                                                      .user_id,
                                                                  currentAd
                                                                      .ad_id)
                                                          .then((revData) {
                                                        setState(() {
                                                          isLoading = false;
                                                        });
                                                        goToReviewPage(revData);
                                                      });
                                                    } else {
                                                      reviewedAds.add(
                                                          '${currentAd.ad_id}');
                                                      cUP.saveString(
                                                          Constants
                                                              .peerVendorsReviews,
                                                          reviewedAds
                                                              .join(','));
                                                      goToReviewPage(null);
                                                    }
                                                  } else {
                                                    markAdAsSoldOrDeleted(
                                                        currentAd.ad_id,
                                                        'sold');
                                                  }
                                                }),
                                          ),
                                          const SizedBox(height: 20),
                                          showSimilarAds
                                              ? Center(
                                                  child: Text(
                                                  AppLocalizations.of(context)
                                                      .similarAds,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ))
                                              : const SizedBox.shrink(),
                                          showSimilarAds
                                              ? Utils.buildSeparator(
                                                  SizeConfig.screenWidth)
                                              : const SizedBox.shrink(),
                                          const SizedBox(height: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                  showSimilarAds
                                      ? GridView.builder(
                                          shrinkWrap: true,
                                          primary: false,
                                          itemCount:
                                              similarAds.ads_details.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisExtent: 250,
                                          ),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return BuildAdTile(
                                              currentHomePageAds: similarAds,
                                              currentUser: currentUser,
                                              currentAddress:
                                                  widget.currentAddress,
                                              cUP: cUP,
                                              adsDetail:
                                                  similarAds.ads_details[index],
                                            );
                                          })
                                      : const SizedBox.shrink()
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Utils.messageWidget(
                        context, AppLocalizations.of(context).detailsNotFound),
            bottomNavigationBar: BottomAppBar(
              color: Colors.white,
              child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isLoading
                      ? const SizedBox(height: 1)
                      : showProductInteractionWidget()),
            )));
  }

  goToReviewPage(ReviewData prevReview) {
    Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => AddReview(
              userModel: currentUser,
              adDetails: currentAd,
              previousReview: prevReview),
        ));
  }

  Widget showProductInteractionWidget({bool shouldHavePadding = true}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: ElevatedButton.icon(
                    style: elevatedButtonStyle(),
                    onPressed: () {
                      if (currentUserIsAdSeller) {
                        markAdAsSoldOrDeleted(currentAd.ad_id, 'deleted');
                      } else {
                        initiateChat();
                      }
                    },
                    label: currentUserIsAdSeller
                        ? Text(AppLocalizations.of(context).delete,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18))
                        : Text(AppLocalizations.of(context).message,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                    icon: currentUserIsAdSeller
                        ? const Icon(Icons.delete_forever_outlined,
                            color: Colors.red)
                        : const Icon(FontAwesomeIcons.commentDots,
                            color: Colors
                                .blueAccent) //const Icon(Icons.chat, color: Colors.blueAccent),
                    )),
            const SizedBox(width: 5),
            Expanded(
                child: ElevatedButton.icon(
                    style: elevatedButtonStyle(primaryColor: Colors.white),
                    icon: currentUserIsAdSeller
                        ? const Icon(
                            FontAwesomeIcons.edit,
                            color: Colors.blue,
                          )
                        : const Icon(FontAwesomeIcons.whatsapp,
                            color: Colors.green),
                    label: currentUserIsAdSeller
                        ? Text(
                            AppLocalizations.of(context).edit,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          )
                        : Text(
                            AppLocalizations.of(context).call,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                    onPressed: () async {
                      if (currentUserIsAdSeller) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => UploadForm(
                                categoryId: currentAd.category_id.toString(),
                                editedAdInfo: currentAd),
                          ),
                        );
                      } else {
                        UserModelProfile seller =
                            await ApiRequest.getUserInfo(currentAd.seller_id);
                        String sellerPhone = seller?.customer_info?.phoneNumber;
                        if (sellerPhone != null &&
                            sellerPhone.endsWith('000000000')) {
                          Map<String, String> params = {
                            'to_firebase_id': currentAd.seller_id.toString(),
                            'title': 'Phone Number Request',
                            'user_lang': currentUser.user_lang,
                            'from_name': currentUser.username,
                            'message': 'RequestToAddPhoneNumber',
                            'is_customer_service': false.toString(),
                            'senders_user_id': currentUser.user_id.toString(),
                            'image': currentAd.images[0],
                            'addition_info': currentAd.sellerName,
                            'senders_profile': '${currentUser.profilePicture}'
                          };
                          ApiRequest.sendPushNotification(params: params);
                          Utils.setDialog(context,
                              title: AppLocalizations.of(context).call,
                              children: [
                                Text(
                                  AppLocalizations.of(context).callNotAvailable,
                                  style: const TextStyle(fontSize: 16),
                                )
                              ],
                              actions: [
                                ElevatedButton.icon(
                                    style: elevatedButtonStyle(),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      initiateChat();
                                    },
                                    icon: const Icon(Icons.message,
                                        color: Colors.blue),
                                    label: Text(
                                      AppLocalizations.of(context)
                                          .chatWithSeller,
                                      style: const TextStyle(
                                          color: Colors.blueAccent),
                                    )),
                                ElevatedButton(
                                  child:
                                      Text(AppLocalizations.of(context).gotIt),
                                  onPressed: () => Navigator.pop(context),
                                )
                              ]);
                        } else if (sellerPhone != null &&
                            !sellerPhone.endsWith('000000000')) {
                          WhatsAppUnilink link = WhatsAppUnilink(
                              phoneNumber:
                                  "+" + sellerPhone.replaceAll('+', '').trim(),
                              text:
                                  "${AppLocalizations.of(context).hello} ${currentAd.sellerName},\n${AppLocalizations.of(context).myNameIs} ${currentUser.username}.\n${AppLocalizations.of(context).wouldLoveToBuyYourItem}\n'${currentAd.item_name}'\n${currentAd.price}");

                          try {
                            await launch('$link');
                          } catch (e) {
                            String localPhone = Constants.getLocalPhoneNumber(
                                countryCode: currentUser.country_code,
                                internationalPhoneNumber: sellerPhone);
                            String phoneScheme = "tel:$localPhone";
                            if (await canLaunch(phoneScheme)) {
                              await launch(phoneScheme);
                            }
                          }
                        } else {
                          Utils.showToast(
                              context,
                              AppLocalizations.of(context).uploadFailed,
                              Colors.pink);
                        }
                      }
                    })),
          ],
        ),
        const SizedBox(height: 1)
      ],
    );
  }

  ButtonStyle elevatedButtonStyle(
      {double borderRadius = 15.0,
      Color primaryColor = Colors.white,
      Color borderColor = Colors.indigo}) {
    return ElevatedButton.styleFrom(
      primary: primaryColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor)),
    );
  }

  initiateChat() {
    List<int> userIds = [currentAd.seller_id, currentUser.user_id];
    userIds.sort();
    List<String> userNames = [currentAd.sellerName, currentUser.username];
    userNames.sort();
    String chatRoomId = '${userIds[0]}_${userIds[1]}';
    Map<String, dynamic> chatRoomDetails = {
      "chatRoomId": chatRoomId,
      "userNames": userNames,
      "userId1": userIds[0],
      "userId2": userIds[1],
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
      "lastAdImage": currentAd.images[0],
      "lastAdTitle": currentAd.item_name,
      "lastDescription": currentAd.item_description,
      "lastAdPrice": currentAd.price,
      "lastAdId": currentAd.ad_id
    };
    if (currentUser.user_id == userIds[0]) {
      chatRoomDetails['userProfile1'] = currentUser.profilePicture;
    } else {
      chatRoomDetails['userProfile2'] = currentUser.profilePicture;
    }
    if (chatRoomId != null) {
      firestoreDb.addChatRoom(
          chatRoomDetails: chatRoomDetails, chatRoomId: chatRoomId);
      Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => Chat(
                cUP: widget.cUP,
                currentUser: currentUser,
                otherUsersUserId: currentAd.seller_id,
                chatRoomId: chatRoomId,
                toUserName: currentAd.sellerName,
                userLang: currentUser.user_lang,
                fromUserName: currentUser.username,
                chatRoomDetails: chatRoomDetails,
                isCustomerService: false,
                image: currentAd.images[0]),
          ));
    }
  }

  markAdAsSoldOrDeleted(int adId, String action) async {
    Map<String, String> map = {
      'ad_id': currentAd.ad_id.toString(),
      'mark_reason': action
    };
    setState(() {
      isLoading = true;
    });
    var t = await ApiRequest.markAdAsSoldDeletedOrExpired(map);
    String message = action == 'sold'
        ? AppLocalizations.of(context).addMarkedAsSold
        : AppLocalizations.of(context).addDeletedSuccessfully;
    setState(() {
      isLoading = false;
    });
    if (t != null) {
      Utils.showToast(context, message, colorSuccess);
      Navigator.pop(context, true);
    } else {
      Utils.showToast(
          context, AppLocalizations.of(context).actionNotPerformed, colorError);
    }
  }
}

class WhatsAppWidget extends StatelessWidget {
  final IconData iconData;
  final String message;
  final String language;
  final String countryCode;
  final int userId;
  final Color color;
  final bool showMessage;
  final bool isCustomerSupport;
  int categoryId;
  UserModel user;

  WhatsAppWidget(
      {Key key,
      @required this.iconData,
      @required this.showMessage,
      @required this.message,
      @required this.countryCode,
      @required this.language,
      @required this.userId,
      @required this.color,
      @required this.isCustomerSupport,
      this.categoryId,
      this.user})
      : super(key: key);

  String getSupportPhone() {
    String cc = '${countryCode}'.toLowerCase().trim();
    if ('cm td ml sn tg cf bj bf ga fg gw cg cd ci ne tg'.contains(cc)) {
      return "+237676297472";
    } else if ('tz rw ug ke so sd mw cd za bw zm ss'.contains(cc)) {
      return "+250781976155";
    } else if ('ng' == cc) {
      return "+2348121693506";
    } else {
      return '+13016408856';
    }
  }

  String getWhatsAppMessage(BuildContext context) {
    if (isCustomerSupport) {
      return "${AppLocalizations.of(context).hello} Peer Vendors ${AppLocalizations.of(context).customerService}, ${AppLocalizations.of(context).iNeedHelp} ...";
    }
    return message;
  }

  launchWhatsApp(BuildContext context) async {
    WhatsAppUnilink link;
    String numb = getSupportPhone();
    if (user?.user_id != null && categoryId > -1) {
      ApiRequest.informNeedToVerifyCategory(params: {
        'user_id': user.user_id.toString(),
        'device_ids': user.deviceIds,
        'lang': user.user_lang,
        'username': user.username,
        'firebase_id': user.firebaseUserId,
        'phone_number': user.phoneNumber,
        'email': user.email,
        'category_id': categoryId.toString()
      });
    }
    try {
      link =
          WhatsAppUnilink(phoneNumber: numb, text: getWhatsAppMessage(context));
      await launch('$link');
    } catch (e) {
      Map<String, dynamic> contactInfo = await ApiRequest.getSupportPhoneNumber(
          userId, countryCode, language, message);
      String number = '+1 (301) 640-8856';
      if (contactInfo != null) {
        try {
          link = WhatsAppUnilink(
              phoneNumber:
                  "+" + contactInfo['whatsAppNumber'].replaceAll('+', ''),
              text: contactInfo['message']);

          await launch('$link');
        } catch (e) {
          Clipboard.setData(ClipboardData(text: number));
          Utils.showToast(context, number + AppLocalizations.of(context).copied,
              Colors.green);
        }
      } else {
        Clipboard.setData(ClipboardData(text: number));
        Utils.showToast(context, number + AppLocalizations.of(context).copied,
            Colors.green);
      }
    }
  }

  Widget whatsAppIcon() {
    return Icon(iconData, color: color);
  }

  Widget whatsAppButton(BuildContext context) {
    return IconButton(
        padding: const EdgeInsets.all(0.0),
        icon: whatsAppIcon(),
        onPressed: () async {
          await launchWhatsApp(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return !showMessage
        ? Container(
            decoration: Utils.containerBoxDecoration(borderColor: Colors.grey),
            child: whatsAppButton(context))
        : ElevatedButton.icon(
            style: Utils.roundedButtonStyle(
                primaryColor: Colors.green,
                radius: 5,
                minSize: Size(SizeConfig.screenWidth * 0.6, 38)),
            icon: whatsAppIcon(),
            label: Text(
              message,
              style: TextStyle(color: color),
            ),
            onPressed: () async {
              await launchWhatsApp(context);
            },
          );
  }
}

class BuildAdTile extends StatelessWidget {
  final AdsDetail adsDetail;
  final ProductListForHomePage currentHomePageAds;
  final UserModel currentUser;
  final UserPreferences cUP;
  final Map<String, dynamic> currentAddress;

  BuildAdTile(
      {Key key,
      this.currentAddress,
      this.currentHomePageAds,
      @required this.adsDetail,
      @required this.cUP,
      @required this.currentUser})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
                adsDetail: adsDetail,
                currentHomePageAds: currentHomePageAds,
                currentUser: currentUser,
                currentAddress: currentAddress,
                cUP: cUP),
          ),
        ),
        child: Container(
            decoration: BoxDecoration(borderRadius: Utils.borderRadius()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: Utils.borderRadius(),
                  child: Image.network(
                    '${Constants.imageBaseUrl}${adsDetail.images[0]}',
                    height: 200.0,
                    fit: BoxFit.cover,
                    width: SizeConfig.screenWidth / 2,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return SizedBox(
                          height: 200,
                          child: Center(
                              child: Utils.loadingWidget(
                                  AppLocalizations.of(context).loadingImage)),
                        );
                      }
                    },
                    errorBuilder: (context, exception, trace) {
                      return Image.asset(
                        'assets/images/img_product_placeholder.jpg',
                        height: 200.0,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                buildAdsTitle(adsDetail,
                    padding: EdgeInsets.symmetric(horizontal: 3), fontSize: 12),
                buildAdsTitle(adsDetail,
                    padding: EdgeInsets.all(2), isPrice: true),
              ],
            )),
      ),
    );
  }

  Widget buildAdsTitle(AdsDetail ad,
      {EdgeInsetsGeometry padding = const EdgeInsets.all(4),
      int maxLines = 1,
      double fontSize = 16,
      bool isPrice = false}) {
    return Padding(
        padding: padding,
        child: Text(
          isPrice ? '${ad.price}' : '${ad.item_name}',
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontSize: fontSize),
          textAlign: TextAlign.right,
        ));
  }
}
