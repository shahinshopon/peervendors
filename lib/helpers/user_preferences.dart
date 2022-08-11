import 'dart:convert';
import 'package:flutter/cupertino.dart';

import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  SharedPreferences _sharedPreferences;
  bool prefsHaveBeenSet = false;
  static String notificationsList = "notificationsList";

  Future<bool> setUserPreferences() async {
    if (prefsHaveBeenSet == true) {
      return true;
    } else {
      _sharedPreferences = await SharedPreferences.getInstance();
      prefsHaveBeenSet = true;
      return true;
    }
  }

  Future<bool> setTimeWhenEventHappened({@required String eventName}) async {
    int timeNow = DateTime.now().millisecondsSinceEpoch;
    return _sharedPreferences.setInt(eventName, timeNow);
  }

  Future<bool> setInt(String key, int value) async {
    return _sharedPreferences.setInt(key, value);
  }

  bool getBool({@required String key}) {
    return _sharedPreferences.containsKey(key)
        ? _sharedPreferences.getBool(key)
        : null;
  }

  Future<String> getCurrencyAsync() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    String userCurrency =
        _sharedPreferences.getString(Constants.peerVendorsCurrencySymbol);
    return userCurrency;
  }

  Future<String> getLastVerificationCodes() async {
    String pvCodes = Constants.peerVendorsLastVCodes;
    String pvTime = Constants.whenLastVerificationCodeWasSent;
    if (_sharedPreferences.containsKey(pvTime)) {
      int lastTime = _sharedPreferences.getInt(pvTime) ?? 0;
      if (lastTime == 0) {
        return '';
      }
      DateTime lastUpdateDateTime =
          DateTime.fromMillisecondsSinceEpoch(lastTime);
      int munitesSinceLastUpdate =
          DateTime.now().difference(lastUpdateDateTime).inMinutes;
      if (munitesSinceLastUpdate > 10) {
        return '';
      }
      return truncateCodes(_sharedPreferences.getString(pvCodes));
    }
    return '';
  }

  static String truncateCodes(String vCodes) {
    List<String> codes =
        vCodes.split(',').where((element) => element.length == 6).toList();
    return codes.length > 3 ? codes.sublist(3).join(',') : codes.join(',');
  }

  int getTimeWhenEventHppened({@required String eventName}) {
    int lastUpdateTime = _sharedPreferences.containsKey(eventName)
        ? _sharedPreferences.getInt(eventName)
        : 0;
    return lastUpdateTime;
  }

  bool canExtractAddress(int diffInMins, {String key}) {
    String nkey = key ?? Constants.whenAddresLastRequested;
    int lastUpdateTime = _sharedPreferences.containsKey(nkey)
        ? _sharedPreferences.getInt(nkey)
        : 0;
    DateTime now = DateTime.now();
    DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
    Duration diff =
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastUpdateTime));
    return diff.inMinutes > diffInMins;
  }

  Future<bool> saveUser(UserModel user) async {
    return _sharedPreferences.setString(
        Constants.peerVendorsUser, json.encode(user.toJson()));
  }

  Future<UserModel> getUserPrefs() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    return _sharedPreferences.containsKey(Constants.peerVendorsUser)
        ? UserModel.fromJson(json
            .decode(_sharedPreferences.getString(Constants.peerVendorsUser)))
        : null;
  }

  Future<bool> setBool({String key, bool value}) async {
    bool wasBooleanSet = await _sharedPreferences.setBool(key, value);
    return wasBooleanSet;
  }

  Future<bool> saveString(String key, String value) async {
    bool wasStringSaved = await _sharedPreferences.setString(key, value);
    return wasStringSaved;
  }

  List<String> getLikedReviewedOrViewedAds(
      {@required String viewsOrLikesOrReviews}) {
    return _sharedPreferences.containsKey(viewsOrLikesOrReviews)
        ? _sharedPreferences.getString(viewsOrLikesOrReviews).split(',')
        : null;
  }

  String getString(String key) {
    return _sharedPreferences.containsKey(key)
        ? _sharedPreferences.getString(key)
        : null;
  }

  Map<String, dynamic> getCurrentUserAddress() {
    String addressString =
        _sharedPreferences.containsKey(Constants.peerVendorsCurrentAddress)
            ? _sharedPreferences.getString(Constants.peerVendorsCurrentAddress)
            : null;
    return addressString == null ? null : json.decode(addressString);
  }

  String getRecentlySavedAds() {
    return _sharedPreferences.containsKey(Constants.peerVendorsRecentlySavedAds)
        ? _sharedPreferences.getString(Constants.peerVendorsRecentlySavedAds)
        : null;
  }

  List<dynamic> getNotifications() {
    if (_sharedPreferences.containsKey(notificationsList)) {
      List<dynamic> pastNots =
          json.decode(_sharedPreferences.getString(notificationsList));
      return pastNots;
    }
    return [];
  }

  Future<bool> modifyNotifications(
      {Map<String, dynamic> notification = const {},
      bool isNewNotification = true,
      num receiveTime = 0}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (isNewNotification) {
      notification['receiveTime'] = now;
      if (_sharedPreferences.containsKey(notificationsList)) {
        String notifications = _sharedPreferences.getString(notificationsList);
        List<dynamic> pastNots = json.decode(notifications);
        pastNots
            .removeWhere((element) => now - element['receiveTime'] > 604800000);
        pastNots.add(notification);
        return _sharedPreferences.setString(
            notificationsList, json.encode(pastNots));
      } else {
        return _sharedPreferences.setString(
            notificationsList, json.encode([notification]));
      }
    } else if (_sharedPreferences.containsKey(notificationsList)) {
      List<dynamic> pastNots =
          json.decode(_sharedPreferences.getString(notificationsList));
      pastNots.removeWhere((element) => element['receiveTime'] == receiveTime);
      return _sharedPreferences.setString(
          notificationsList, json.encode(pastNots));
    } else {
      return false;
    }
  }

  Future<bool> saveHomePageAds({ProductListForHomePage homePageAds}) async {
    if (homePageAds != null && homePageAds.ads_details.isNotEmpty) {
      ProductListForHomePage finalAds = ProductListForHomePage();
      finalAds.ads_details = [];
      List<int> adIds = [];
      for (AdsDetail adsDetail in homePageAds.ads_details) {
        if (!adIds.contains(adsDetail.ad_id)) {
          finalAds.ads_details.add(adsDetail);
          adIds.add(adsDetail.ad_id);
        }
      }
      Map<String, dynamic> adsJson = finalAds.toJson();
      bool res = await _sharedPreferences.setString(
          Constants.peerVendorsRecentlySavedAds, json.encode(adsJson));
      int timeNow = DateTime.now().millisecondsSinceEpoch;
      await _sharedPreferences.setInt(
          Constants.whenHomePageAdsWereExtracted, timeNow);
      return res;
    } else {
      return false;
    }
  }

  SongList getUserSong({String songsType = Constants.peerVendorsSavedSongs}) {
    String mySongs = _sharedPreferences.containsKey(songsType)
        ? _sharedPreferences.getString(songsType)
        : null;
    if (mySongs != null) {
      List<dynamic> ownedSongs = jsonDecode(mySongs);
      return SongList.fromSongMapList(ownedSongs);
    } else {
      return SongList.fromSongMapList([]);
    }
  }

  UserModel getCurrentUser() {
    String currentUserString =
        _sharedPreferences.containsKey(Constants.peerVendorsUser)
            ? _sharedPreferences.getString(Constants.peerVendorsUser)
            : null;
    if (currentUserString != null) {
      UserModel currentUser =
          UserModel.fromJson(json.decode(currentUserString));
      return currentUser;
    }
    return null;
  }

  removePrefsKey(String key) async {
    if (_sharedPreferences.containsKey(key)) {
      return await _sharedPreferences.remove(key);
    }
    return false;
  }

  clearPrefs() async {
    await _sharedPreferences.clear();
  }

  Future<bool> setAccountStatusActive({bool isActive: false}) async {
    bool isAccountStatusSet = await _sharedPreferences.setBool(
        Constants.peerVendorsAccountStatus, isActive);
    return isAccountStatusSet;
  }

  Set<String> getKeys() {
    Set<String> allKeys = _sharedPreferences.getKeys();
    return allKeys;
  }
}
