import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:peervendors/HomeScreen/Nav_Bar_Pages/sell_screen.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/app_version.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/default_addresses.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:peervendors/helpers/play_videos.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/helpers/addresses.dart';
import 'package:peervendors/models/categories_model.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/views/contact_us.dart';
import 'package:peervendors/views/product_details.dart';
//import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../Responsive/sizeconfig.dart';
import '../../models/product_list_home.dart';

class HomeScreen extends StatefulWidget {
  final ProductListForHomePage homePageProducts;
  UserModel currentUser;
  UserPreferences cUP = UserPreferences();

  HomeScreen(
      {Key key,
      @required this.cUP,
      @required this.currentUser,
      @required this.homePageProducts})
      : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  bool _isSearchingCategory = false;
  bool isSavingFile = false;
  bool isPlaying = false;
  final player = AudioPlayer();
  ProductListForHomePage listOfHomePageProducts =
      ProductListForHomePage(ads_details: []);
  ScrollController homePageScrollController = ScrollController();
  int loadedIndexOfAds = 6;
  Map<String, dynamic> currentUsersAddress = {};
  String currentHomePageLocation;
  TextEditingController searchEditingController = TextEditingController();
  bool userHasFinishedSearchSearching = false;
  final List<CategoryData> allCategories = CategoriesModel.categories;
  String trending = '';
  var notifications = [];
  int playingIndex = 0;
  UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  List<String> musicfiles = [];
  bool canLoadMoreAds = true;
  VideoPlayerController _locationVideoController;
  Future<void> _initializeLocationVideoPlayerFuture;

  VideoPlayerController _generalVideoController;
  Future<void> _initializeGeneralVideoPlayerFuture;

  @override
  void initState() {
    isLoading = true;
    super.initState();
    if (currentUsersAddress.isEmpty) {
      setUserPrefs().then((value) {
        isLoading = false;
      });
    }
    homePageScrollController.addListener(() {
      if (homePageScrollController.position.pixels ==
          homePageScrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });
  }

  void _checkVersion() async {
    var b = await Future.wait(
        [ApiRequest.getAppVersion(), AppVersion.getAppVersion()]);
    if (b[0] != b[1] && !b.contains(null)) {
      cUP.setTimeWhenEventHappened(
          eventName: Constants.peerVendorsCheckForUpdates);
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              title: Center(
                  child: Column(children: [
                Utils.buildText(AppLocalizations.of(context).updatesAvailable,
                    color: Colors.blueAccent, fontSize: 20),
                Utils.buildSeparator(SizeConfig.screenWidth * 0.75),
                const SizedBox(height: 15),
                Text(
                  AppLocalizations.of(context)
                      .updateAppMessage
                      .replaceAll('100', b.last)
                      .replaceAll('200', b.first),
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 15),
              ])),
              actions: [
                ElevatedButton(
                    style: Utils.roundedButtonStyle(primaryColor: Colors.pink),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).maybeLater)),
                ElevatedButton(
                    style: Utils.roundedButtonStyle(primaryColor: Colors.green),
                    onPressed: () async {
                      try {
                        await launch(
                            'https://play.google.com/store/apps/details?id=com.peervendors');
                      } catch (e) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(AppLocalizations.of(context).updateNow))
              ],
            );
          });
    } else {
      Utils.showToast(context, AppLocalizations.of(context).noUpdatesAvailable,
          Colors.green,
          duration: 6);
    }
  }

  _getMoreData({shouldLoadMore = false}) {
    if (loadedIndexOfAds + 2 <= listOfHomePageProducts.ads_details.length) {
      loadedIndexOfAds += 2;
    } else if (canLoadMoreAds &&
        loadedIndexOfAds >= 50 &&
        loadedIndexOfAds <= 150) {
      loadedIndexOfAds = listOfHomePageProducts.ads_details.length;
      // var ids = listOfHomePageProducts.ads_details.map((e) => e.ad_id).toList();
      // int startingAdId = ids.reduce(max);
      int startingAdId = listOfHomePageProducts.ads_details[0].ad_id;

      ApiRequest.getAdsInLocation(
              lat: currentUsersAddress['lat'],
              lng: currentUsersAddress['lng'],
              currencySymbol: currentUser.currencySymbol,
              startAdId: startingAdId,
              countryCode: currentUser.country_code,
              expandedSearch: 1)
          .then((moreAds) {
        if (moreAds != null && moreAds.ads_details.isNotEmpty) {
          listOfHomePageProducts.ads_details.addAll(moreAds.ads_details);
          cUP.saveHomePageAds(homePageAds: listOfHomePageProducts);
          if (moreAds.ads_details.length < 70 ||
              listOfHomePageProducts.ads_details.length > 120) {
            canLoadMoreAds = false;
          }
        } else {
          canLoadMoreAds = false;
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    searchEditingController.dispose();
    homePageScrollController.dispose();
    if (_locationVideoController != null &&
        (_locationVideoController.value != null ||
            _locationVideoController.value.isInitialized)) {
      _locationVideoController.dispose();
    }

    super.dispose();
  }

  TextStyle simpleTextStyle() {
    return TextStyle(color: Colors.blue[200], fontSize: 16);
  }

  initiateSearch() async {
    String searchedText = searchEditingController.text.trim();
    if (searchedText.isNotEmpty && searchedText.length >= 2) {
      setState(() {
        isLoading = true;
      });
      ProductListForHomePage searchedAds =
          await ApiRequest.getAdsFromSearchQuery(
              lat: currentUsersAddress['lat'],
              lng: currentUsersAddress['lng'],
              searchQuery: searchedText,
              currencySymbol: currentUser.currencySymbol,
              countryCode: currentUser.country_code);
      ProductListForHomePage newAds = ProductListForHomePage.clone(searchedAds);

      if (searchedAds != null && searchedAds.ads_details.isNotEmpty) {
        canLoadMoreAds = false;
        int numberOfSearchedAds = searchedAds.ads_details.length;
        loadedIndexOfAds = min(numberOfSearchedAds, 6);
        Utils.showToast(
            context,
            AppLocalizations.of(context)
                    .found5Ads
                    .replaceAll('5', numberOfSearchedAds.toString()) +
                " '$searchedText'",
            Colors.green);
        searchedAds.addNewAds(listOfHomePageProducts);
        await cUP.saveHomePageAds(homePageAds: searchedAds);
        setState(() {
          trending = AppLocalizations.of(context).searchAdverts;
          listOfHomePageProducts = newAds;
          userHasFinishedSearchSearching = true;
          isLoading = false;
        });
      } else {
        Utils.showToast(
            context,
            AppLocalizations.of(context).noAddsAvailable + ' "$searchedText"',
            Colors.red);
      }
      setState(() {
        isLoading = false;
      });
    } else {
      Utils.showToast(context,
          AppLocalizations.of(context).enterMinimum2Letters, Colors.red);
    }
  }

  Future<bool> haveAdsBeenRecentlySet() async {
    await cUP.setUserPreferences();
    DateTime dateTimeNow = DateTime.now();
    int lastSavedAdsTime = cUP.getTimeWhenEventHppened(
        eventName: Constants.whenHomePageAdsWereExtracted);
    setState(() {
      trending = AppLocalizations.of(context).trending;
      currentUser = cUP.getCurrentUser();
    });
    await setAddress();
    if (lastSavedAdsTime < 100) {
      return false;
    } else {
      DateTime lastUpdateDateTime =
          DateTime.fromMillisecondsSinceEpoch(lastSavedAdsTime);
      int munitesSinceLastUpdate =
          dateTimeNow.difference(lastUpdateDateTime).inMinutes;
      return munitesSinceLastUpdate > 4 ? false : true;
    }
  }

  Future<void> setAddress({bool needsUpdate = false}) async {
    if (needsUpdate) {
      await getAndSetAddress();
    } else {
      Map<String, dynamic> lastAddress = cUP.getCurrentUserAddress();
      if (lastAddress == null || lastAddress.isNotEmpty) {
        setState(() {
          currentUsersAddress = lastAddress;
          currentHomePageLocation =
              "${lastAddress['city']}, ${lastAddress['state']}";
        });
      } else {
        currentUsersAddress = DefaultAddresses.getDefaultAddres(
            countryCode: currentUser.country_code);
        currentHomePageLocation =
            "${currentUsersAddress['city']}, ${currentUsersAddress['state']}";
        await getAndSetAddress();
      }
    }
    setState(() {});
  }

  Future getAndSetAddress() async {
    Map<String, dynamic> address = await Addresses.getAddressFromBackend();
    if (address?.isNotEmpty == true) {
      cUP.saveString(Constants.peerVendorsCurrentAddress, json.encode(address));
      setState(() {
        currentUsersAddress = address;
        currentHomePageLocation = "${address['city']}, ${address['state']}";
      });
    } else {
      initializeVideo("updateLocation");
      Utils.showToast(
          context,
          AppLocalizations.of(context).location +
              ' ' +
              AppLocalizations.of(context).permissionsNeeded +
              '\n' +
              AppLocalizations.of(context).couldNotGetYourLocation,
          Colors.pink);
      address = await ApiRequest.getAddressFromAddressId(params: {
        'address_id': currentUser.address_id.toString(),
        'user_id': currentUser.user_id.toString()
      });
      if (address == null || address.isEmpty) {
        address = DefaultAddresses
            .defaultAddresses[currentUser.country_code.toUpperCase()];
      }
      currentUsersAddress = address;
      cUP.saveString(Constants.peerVendorsCurrentAddress, json.encode(address));
      currentHomePageLocation = "${address['city']}, ${address['state']}";
    }
    listOfHomePageProducts = await ApiRequest.getAdsInLocation(
        lat: address['lat'],
        lng: address['lng'],
        countryCode: currentUser.country_code,
        currencySymbol: currentUser.currencySymbol);
    int numbAds = listOfHomePageProducts?.ads_details?.length;
    if (numbAds != null && numbAds > 0) {
      cUP.saveHomePageAds(homePageAds: listOfHomePageProducts);
      canLoadMoreAds = numbAds >= 70;
      loadedIndexOfAds = min(numbAds, 6);
    }
    setState(() {});
  }

  Future setUserPrefs() async {
    bool adsHaveRecentlyBeenUpdated = await haveAdsBeenRecentlySet();
    if (adsHaveRecentlyBeenUpdated || widget.homePageProducts != null) {
      if (widget.homePageProducts != null) {
        int numberOfAds = widget.homePageProducts.ads_details.length;
        setState(() {
          loadedIndexOfAds = min(numberOfAds, 6);
          canLoadMoreAds = numberOfAds >= 60;
          listOfHomePageProducts = widget.homePageProducts;
          isLoading = false;
        });
      } else {
        String recentlySavedAds = cUP.getRecentlySavedAds();
        ProductListForHomePage plistOfHomePageProducts =
            ApiRequest.getRecentlySavedHomePageAds(
                recentlySavedAds: recentlySavedAds);
        // plistOfHomePageProducts.ads_details = [];
        // plistOfHomePageProducts.ads_details.sublist(70);
        int numberOfAds = plistOfHomePageProducts != null
            ? plistOfHomePageProducts.ads_details.length
            : 0;
        setState(() {
          loadedIndexOfAds = min(numberOfAds, 6);
          listOfHomePageProducts = plistOfHomePageProducts;

          isLoading = false;
          canLoadMoreAds = numberOfAds >= 120;
        });
        if (plistOfHomePageProducts == null ||
            plistOfHomePageProducts.ads_details.isEmpty) {
          initializeVideo("updateLocation");
          initializeVideo("howToUseApp");
        }
      }
    } else {
      notifications = cUP.getNotifications();
      if (currentUsersAddress.isNotEmpty) {
        if (widget.homePageProducts != null) {
          int numberOfAds = widget.homePageProducts.ads_details.length;
          setState(() {
            listOfHomePageProducts = widget.homePageProducts;
            loadedIndexOfAds = min(numberOfAds, 6);
            canLoadMoreAds = false;
            isLoading = false;
          });
        } else {
          ApiRequest.getAdsInLocation(
                  lat: currentUsersAddress['lat'],
                  lng: currentUsersAddress['lng'],
                  countryCode: currentUser.country_code,
                  currencySymbol: currentUser.currencySymbol)
              .then((listOfProducts) {
            cUP.saveHomePageAds(homePageAds: listOfProducts);
            if (listOfProducts != null) {
              int numberOfAds = listOfProducts.ads_details.length;
              if (numberOfAds == 0) {
                initializeVideo("updateLocation");
                initializeVideo("howToUseApp");
              }
              canLoadMoreAds = numberOfAds >= 70;
              loadedIndexOfAds = min(numberOfAds, 6);
            }
            setState(() {
              listOfHomePageProducts = listOfProducts;
              isLoading = false;
            });
          });
        }
      } else {
        getAndSetAddress();
      }
    }
  }

  Future getAdsForExpandedSearch() async {
    setState(() {
      isLoading = true;
    });
    ApiRequest.getAdsInLocation(
            lat: currentUsersAddress['lat'],
            lng: currentUsersAddress['lng'],
            currencySymbol: currentUser.currencySymbol,
            countryCode: currentUser.country_code,
            expandedSearch: 1)
        .then((listOfProducts) {
      cUP.saveHomePageAds(homePageAds: listOfProducts);
      int numberOfAds =
          listOfProducts != null ? listOfProducts.ads_details.length : 0;
      canLoadMoreAds = numberOfAds == 70;
      setState(() {
        listOfHomePageProducts = listOfProducts;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: TextButton.icon(
            icon: const Icon(
              Icons.location_on,
              color: Colors.white,
            ),
            label: Text('$currentHomePageLocation',
                style: Utils.addressStyle(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            onPressed: () {
              Utils.setDialog(context,
                  title: AppLocalizations.of(context).wantToUpdatLocation,
                  children: [
                    Text(AppLocalizations.of(context).yesUpdateLcation + '\n'),
                    Text(AppLocalizations.of(context).noDoNotUpdateLocation)
                  ],
                  actions: [
                    ElevatedButton(
                        style: Utils.roundedButtonStyle(),
                        child: Text(AppLocalizations.of(context).yes),
                        onPressed: () async {
                          Navigator.pop(context);
                          await setAddress(needsUpdate: true);
                        }),
                    ElevatedButton(
                      style:
                          Utils.roundedButtonStyle(primaryColor: Colors.pink),
                      child: Text(AppLocalizations.of(context).no),
                      onPressed: () => Navigator.pop(context),
                    )
                  ]);
            },
          ),
          actions: <Widget>[
            buildContactOptions(),
            Badge(
                position: BadgePosition.topEnd(end: 1, top: -1),
                badgeContent: notifications.isEmpty
                    ? const SizedBox.shrink()
                    : Text(notifications.length.toString()),
                child: IconButton(
                    icon: Icon(FontAwesomeIcons.bell),
                    onPressed: () async {
                      if (notifications.isNotEmpty) {
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                  builder: (context, setState) {
                                List<Widget> notifs = notifications
                                    .map((e) => Badge(
                                          padding: const EdgeInsets.all(0.0),
                                          badgeContent: IconButton(
                                              iconSize: 20,
                                              icon: Icon(Icons.close),
                                              onPressed: () {
                                                notifications.removeWhere(
                                                    (element) =>
                                                        e['receiveTime'] ==
                                                        element['receiveTime']);
                                                cUP
                                                    .modifyNotifications(
                                                        receiveTime:
                                                            e['receiveTime'],
                                                        isNewNotification:
                                                            false)
                                                    .then((val) {});
                                                setState(() {});
                                                if (notifications.isEmpty) {
                                                  Navigator.of(context).pop();
                                                }
                                              }),
                                          child: Card(
                                            child: ListTile(
                                                title: Text("${e['title']}"),
                                                subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text("${e['body']}"),
                                                      Text(
                                                          "${FirestoreDB().convertTimeStampToDisplayTimeString(e['receiveTime'])}")
                                                    ])),
                                          ),
                                        ))
                                    .toList();

                                notifs = List.from(notifs.reversed);
                                return AlertDialog(
                                    insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    title: Center(
                                      child: Text(AppLocalizations.of(context)
                                          .notifications),
                                    ),
                                    content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: notifs),
                                    actions: <Widget>[
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .gotIt))
                                    ]);
                              });
                            });
                        setState(() {});
                      }
                    }))
          ],
          backgroundColor: Colors.blue[700],
          elevation: 0,
        ),
        body: SafeArea(child: buildAdsBody()));
  }

  Widget buildAdsBody() {
    return !isLoading
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ElevatedButton(
            //     onPressed: () async {
            //       var nots = cUP.getNotifications();
            //       if (nots.isNotEmpty) {
            //         notifications = nots;
            //         //"${nots.length}";
            //         setState(() {});
            //       }
            //     },
            //     child: Text('hello')),
            ListTile(
              horizontalTitleGap: 2,
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              title: TextField(
                controller: searchEditingController,
                onSubmitted: (sq) {
                  initiateSearch();
                },
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal)),
                  hintText: AppLocalizations.of(context).egMobilePhones,
                  labelText: AppLocalizations.of(context).searchAdverts,
                  suffixIcon: IconButton(
                      hoverColor: Colors.red,
                      icon: const Icon(
                        Icons.search,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        initiateSearch();
                      }),
                  prefixText: ' ',
                ),
              ),
              trailing: WhatsAppWidget(
                  iconData: FontAwesomeIcons.phone,
                  showMessage: false,
                  isCustomerSupport: true,
                  color: Colors.green,
                  message:
                      "${AppLocalizations.of(context).hello} Peer Vendors ${AppLocalizations.of(context).customerService}, ${AppLocalizations.of(context).iNeedHelp} ...",
                  userId: currentUser.user_id,
                  language: currentUser.user_lang,
                  countryCode: currentUser.country_code),
            ),
            currentUsersAddress.isNotEmpty
                ? !_isSearchingCategory
                    ? Container(
                        decoration: Utils.containerBoxDecoration(radius: 20),
                        height: 50,
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: CategoriesModel.categoriesMap
                                    .map((category) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: ElevatedButton(
                                              style: Utils.roundedButtonStyle(
                                                  primaryColor: Colors.blue,
                                                  radius: 7),
                                              onPressed: () async {
                                                Map<String, dynamic> address =
                                                    widget.cUP
                                                        .getCurrentUserAddress();
                                                if (address != null) {
                                                  setState(() {
                                                    _isSearchingCategory = true;
                                                  });
                                                  ProductListForHomePage pdts =
                                                      await ApiRequest
                                                          .adsInCategory(
                                                              address['lat'],
                                                              address['lng'],
                                                              category[
                                                                  'category_id'],
                                                              currentUser
                                                                  .currencySymbol,
                                                              currentUser
                                                                  .country_code);
                                                  if (pdts != null) {
                                                    var n =
                                                        pdts.ads_details.length;
                                                    if (listOfHomePageProducts ==
                                                        null) {
                                                      listOfHomePageProducts =
                                                          pdts;
                                                    } else {
                                                      listOfHomePageProducts
                                                          .addNewAds(pdts);
                                                    }
                                                    await cUP.saveHomePageAds(
                                                        homePageAds:
                                                            listOfHomePageProducts);
                                                    var t = AppLocalizations.of(
                                                            context)
                                                        .found5Ads
                                                        .replaceAll('5', '$n');
                                                    Utils.showToast(context, t,
                                                        Colors.green);
                                                  } else {
                                                    listOfHomePageProducts =
                                                        ProductListForHomePage(
                                                            ads_details: []);
                                                  }
                                                  _isSearchingCategory = false;
                                                  setState(() {});
                                                } else {
                                                  Utils.showToast(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .couldNotGetYourLocation,
                                                      Colors.red);
                                                  await getAndSetAddress();
                                                  setState(() {});
                                                }
                                              },
                                              child: Text(category[
                                                  'category_${currentUser.user_lang}'])),
                                        ))
                                    .toList())))
                    : Utils.progressIndicator(color: Colors.red)
                : const SizedBox.shrink(),
            listOfHomePageProducts == null ||
                    listOfHomePageProducts.ads_details.isEmpty
                ? buildAdsNotFound()
                : Expanded(
                    child: listOfHomePageProducts.ads_details.length > 10
                        ? GridView.builder(
                            shrinkWrap: true,
                            itemCount: loadedIndexOfAds,
                            controller: homePageScrollController,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 250,
                              //childAspectRatio: 0.8
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              if (index ==
                                  listOfHomePageProducts.ads_details.length) {
                                return ElevatedButton(
                                    child: const Text(
                                        'Loading more data from backend'),
                                    onPressed:
                                        _getMoreData(shouldLoadMore: true));
                              } else {
                                return BuildAdTile(
                                  currentHomePageAds: listOfHomePageProducts,
                                  currentUser: currentUser,
                                  currentAddress: currentUsersAddress,
                                  cUP: cUP,
                                  adsDetail:
                                      listOfHomePageProducts.ads_details[index],
                                );
                              }
                            })
                        : GridView.builder(
                            shrinkWrap: true,
                            itemCount: loadedIndexOfAds,
                            controller: homePageScrollController,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 250,
                              //childAspectRatio: 0.8
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              return BuildAdTile(
                                currentHomePageAds: listOfHomePageProducts,
                                currentUser: currentUser,
                                currentAddress: currentUsersAddress,
                                cUP: cUP,
                                adsDetail:
                                    listOfHomePageProducts.ads_details[index],
                              );
                            })),
            Center(
                child: canLoadMoreAds &&
                        loadedIndexOfAds >= 68 &&
                        (listOfHomePageProducts != null &&
                            listOfHomePageProducts.ads_details.length -
                                    loadedIndexOfAds <=
                                2)
                    ? Utils.progressIndicator()
                    : const SizedBox(height: 1)),
          ])
        : Utils.loadingWidget(AppLocalizations.of(context).loadingPleaseWait);
  }

  Future showDialogue() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.symmetric(vertical: 10),
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
                  height: 400,
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
                        userId: currentUser.user_id,
                        language: currentUser.user_lang,
                        countryCode: currentUser.country_code),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context).contactViaEmail),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    Utils.buildContactSupportButton(
                        "support@peervendors.com",
                        AppLocalizations.of(context).email,
                        AppLocalizations.of(context).copied,
                        FontAwesomeIcons.at,
                        context),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context).chatWithSupport),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    ElevatedButton.icon(
                        style: styleElevatedButton(),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContactUs(
                                      currentUser: currentUser, cUP: cUP)));
                        },
                        icon: const Icon(Icons.chat),
                        label:
                            Text(AppLocalizations.of(context).chatWithSupport)),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context).checkForAppUpdates),
                    Utils.buildSeparator(SizeConfig.screenWidth,
                        isSmaller: true),
                    ElevatedButton.icon(
                        style: styleElevatedButton(),
                        onPressed: () {
                          Navigator.pop(context);
                          _checkVersion();
                        },
                        icon: const Icon(
                          Icons.update,
                        ),
                        label: Text(
                            AppLocalizations.of(context).checkForAppUpdates)),
                  ]));
            }),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).gotIt))
            ],
          );
        });
  }

  Widget buildContactSupportButton(
      String email, String prefix, IconData iconData) {
    return ElevatedButton.icon(
        style: styleElevatedButton(),
        onPressed: () async {
          Clipboard.setData(ClipboardData(text: email));

          String emailScheme = "mailto:$email";
          if (await canLaunch(emailScheme)) {
            await launch(emailScheme);
          } else {
            Utils.showToast(
                context,
                prefix + ' ' + AppLocalizations.of(context).copied,
                Colors.green);
          }
        },
        icon: Icon(iconData),
        label: Text(email));
  }

  Widget buildContactOptions({bool isIcon = true}) {
    return isIcon
        ? IconButton(
            padding: const EdgeInsets.all(0),
            icon: const Icon(FontAwesomeIcons.solidQuestionCircle),
            onPressed: () {
              showDialogue();
            })
        : ElevatedButton.icon(
            style: styleElevatedButton(),
            label: Text(AppLocalizations.of(context).contactUs),
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              showDialogue();
            });
  }

  Widget buildNoMoreAdsToShow() {
    return Column(
      children: [
        const SizedBox(height: 15),
        Utils.buildSeparator(SizeConfig.screenWidth),
        ButtonTheme(
            minWidth: SizeConfig.screenWidth / 1.7,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, CupertinoPageRoute(builder: (_) => SellScreen()));
              },
              child: Text(
                AppLocalizations.of(context).putUpSomethingForSale,
                style: const TextStyle(color: Colors.white),
              ),
            ))
      ],
    );
  }

  ButtonStyle styleElevatedButton(
      {Color color = Colors.green, double widthFactor = 0.6}) {
    return ElevatedButton.styleFrom(
        primary: color,
        minimumSize: Size(SizeConfig.screenWidth * widthFactor, 35));
  }

  Widget buildAdsNotFound() {
    return currentUsersAddress.isEmpty
        ? Center(
            child: Column(children: [
            TextButton.icon(
                icon: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                ),
                label: Text(AppLocalizations.of(context).fixMyLocationProblem),
                onPressed: () => {setAddress(needsUpdate: true)}),
            OutlinedButton.icon(
              icon: const Icon(
                Icons.play_circle_fill_outlined,
                color: Colors.red,
              ),
              onPressed: () {
                playVideo(_locationVideoController);
              },
              label: Text(
                AppLocalizations.of(context).needHelp,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            ListTile(
              title: Center(
                  child: Text(
                AppLocalizations.of(context).couldNotGetYourLocation,
                style: const TextStyle(color: Colors.pink),
              )),
              subtitle: Container(height: 1, color: Colors.pink),
            ),
            ListTile(
                title: Text(
                    AppLocalizations.of(context).clickToUpdateYourLocation)),
            ListTile(
                title: Text(AppLocalizations.of(context).watchTheVideoForHelp)),
            TextButton(
              child: Text(AppLocalizations.of(context).fixMyLocationProblem),
              onPressed: () async {
                await setAddress(needsUpdate: true);
              },
            )
          ]))
        : Expanded(
            flex: 1,
            child: SingleChildScrollView(
                child: Column(
              children: [
                Utils.messageWidget(context,
                    '${AppLocalizations.of(context).noAddsAvailable} \n $currentHomePageLocation'),
                ButtonTheme(
                    minWidth: SizeConfig.screenWidth / 1.7,
                    child: ElevatedButton(
                      style: styleElevatedButton(color: Colors.blue),
                      onPressed: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (_) => SellScreen()));
                      },
                      child: Text(
                        AppLocalizations.of(context).putUpSomethingForSale,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )),
                Text(AppLocalizations.of(context).or.toUpperCase()),
                ElevatedButton(
                    style: styleElevatedButton(color: Colors.blue),
                    onPressed: getAdsForExpandedSearch,
                    child: Text(
                      AppLocalizations.of(context).searchInNearbyTowns,
                      style: const TextStyle(color: Colors.white),
                    )),
                const SizedBox(height: 25),
                Utils.buildText(AppLocalizations.of(context).customerService,
                    fontSize: 20),
                Utils.buildSeparator(SizeConfig.screenWidth * 0.7),
                buildContactOptions(isIcon: false),
                const SizedBox(height: 25),
                Utils.buildText(
                    '${AppLocalizations.of(context).helpCenter} (${AppLocalizations.of(context).location})',
                    fontSize: 20),
                Utils.buildSeparator(SizeConfig.screenWidth * 0.7),
                TextButton.icon(
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                    label:
                        Text(AppLocalizations.of(context).wantToUpdatLocation),
                    onPressed: () => {setAddress(needsUpdate: true)}),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.play_circle_fill_outlined,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    playVideo(_locationVideoController);
                  },
                  label: Text(
                    AppLocalizations.of(context).fixMyLocationProblem,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 25),
                Utils.buildText(
                    '${AppLocalizations.of(context).helpCenter} (${AppLocalizations.of(context).gettingStarted.split('.').first})',
                    fontSize: 20),
                Utils.buildSeparator(SizeConfig.screenWidth * 0.7),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.play_circle_fill_outlined,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    playVideo(_generalVideoController);
                  },
                  label: Text(
                    AppLocalizations.of(context)
                        .gettingStarted
                        .split('. ')
                        .last,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )));
  }

  void initializeVideo(String reason) {
    String languageCode = Localizations.localeOf(context).languageCode;
    String videoUrl = Utils.getVideoUrl(reason, languageCode);
    if (reason == 'updateLocation' &&
        (_locationVideoController == null ||
            !_locationVideoController.value.isInitialized)) {
      _locationVideoController = VideoPlayerController.network(videoUrl);
      _initializeLocationVideoPlayerFuture =
          _locationVideoController.initialize();
      // Use the controller to loop the video
      _locationVideoController.setLooping(true);
    } else if (_generalVideoController == null ||
        !_generalVideoController.value.isInitialized) {
      _generalVideoController = VideoPlayerController.network(videoUrl);
      _initializeGeneralVideoPlayerFuture =
          _generalVideoController.initialize();
      // Use the controller to loop the video
      _generalVideoController.setLooping(true);
    }
    setState(() {});
  }

  Future playVideo(VideoPlayerController controller) {
    return showDialog(
        barrierDismissible: false,
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
                          if (_generalVideoController.value != null &&
                              (_generalVideoController.value.isInitialized ||
                                  _generalVideoController.value.isPlaying)) {
                            _generalVideoController.pause();
                          }
                          if (_locationVideoController.value != null &&
                              (_locationVideoController.value.isInitialized ||
                                  _locationVideoController.value.isPlaying)) {
                            _locationVideoController.pause();
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context).gotIt)))
              ],
              content: SizedBox(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(controller),
                      ClosedCaption(text: controller.value.caption.text),
                      ControlsOverlay(controller: controller),
                      VideoProgressIndicator(controller, allowScrubbing: true),
                    ],
                  ),
                ),
              ),
            ));
  }
}
