import 'dart:convert';
import 'dart:io';
import "dart:math";
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/send_email.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/models/customer_info.dart';

class ApiRequest {
  static final ApiRequest _request = ApiRequest._internal();
  static Map<String, String> standardHeaders = {
    'Content-type': 'application/json',
    'Accept': 'text/plain'
  };
  static List<String> hEATHERS = [
    "29d20a29-efc3-4eec-be2c-4e845e52051c",
    "38ea57ca-f1a9-462c-a280-4eedfab0328b",
    "7c73feb0-6848-4954-99c5-f4648fa37573",
    "c885089d-65c6-45e2-8ae8-b277e6959338",
    "40f1293d-0c91-4dd3-a989-7e421a0fc7cf",
    "3196c06b-6a43-45e2-81da-002be0f87491",
    "84b8129c-a737-4aec-b574-23a0ac08334e",
    "9483724c-97c3-4e6b-a630-f4b60c2410e1",
    "6571ebed-3682-4ab1-809a-469dc48e7e3f",
    "eeed4ac9-e289-4b0c-9451-54a40f688009",
    "a96a773a-ac56-4c80-9067-4258cb8dfec9"
  ];

  static IOClient https() {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  static HttpClient httpsPost() {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }

  static Map<String, dynamic> getApiRes(http.Response response) {
    return response.statusCode == 200
        ? jsonDecode(utf8.decode(response.bodyBytes))
        : null;
  }

  static ProductListForHomePage getProductListForHomePage(
      http.Response response, String currencySymbol) {
    return response.statusCode == 200
        ? ProductListForHomePage.fromJson(getApiRes(response), currencySymbol)
        : ProductListForHomePage(ads_details: []);
  }

  static String baseUrl = 'https://www.peervendors.com/';

  static Map<String, dynamic> getDecodedContent(http.Response response) {
    Map<String, dynamic> res = json.decode(response.body);
    return res;
  }

  factory ApiRequest() {
    return _request;
  }

  ApiRequest._internal();
  static Map<String, String> getStandardHeaders({bool isPostRequest = false}) {
    final _random = Random();
    Map<String, String> currentHeaders = standardHeaders;
    String header = hEATHERS[_random.nextInt(hEATHERS.length)];
    if (isPostRequest) {
      return {
        'accept': 'application/json',
        'header': header,
        'Content-Type': 'application/x-www-form-urlencoded'
      };
    } else {
      currentHeaders.addAll({"header": header});
      return currentHeaders;
    }
  }

  static Future<Map<String, dynamic>> createOrder(
      {@required Map<String, String> params}) async {
    String url = baseUrl + "create_order";
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200 ? getApiRes(response) : null;
  }

  static Future<Map<String, dynamic>> updateOrder(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'update_order';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<bool> reportVerificationError(
      {@required Map<String, String> params}) async {
    String url = baseUrl + "report_verification_error";
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<bool> sendSharedAppreciation(
      {@required Map<String, String> params}) async {
    String url = baseUrl + "send_share_message_appreciation";
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<bool> notifyInvalidPhone(
      {@required Map<String, String> params}) async {
    String url = baseUrl + "notify_invalid_phone_number";
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<UserModel> isEmailOrPhoneRegistered(
      {String email = 'a-a-a-a-q@gmail.com',
      String internationalPhoneNumber = '0000000000'}) async {
    String url = baseUrl +
        'verify_if_email_or_phone_number_is_registered/$email/$internationalPhoneNumber';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      Map<String, dynamic> res = getApiRes(response);
      return res.length > 4 ? UserModel.fromJson(res) : null;
    } else {
      return null;
    }
  }

  static Future<String> getAppVersion({String platform = 'android'}) async {
    String url = baseUrl + 'get_app_version/$platform';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      return getApiRes(response)['currentVersion'];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> deleteASong(
      int songId, String songMetaDataUrls,
      {String deleteReason = 'ArtistDeleted'}) async {
    String url =
        baseUrl + 'delete_song/$songId/$deleteReason/$songMetaDataUrls';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> getSupportPhoneNumber(
      int userId, String countryCode, String language, String message) async {
    String url =
        baseUrl + 'get_support_number/$userId/$language/$countryCode/$message';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> getPresignedUrl(String image,
      {int adId = 1}) async {
    String url = baseUrl + 'create_presigned_url/$image/$adId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<bool> informNeedToVerifyCategory(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'inform_need_to_verify_category';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<bool> postReasonsForDeletingApp(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'reasons_for_deleting_app';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      return true;
    } else {
      return null;
    }
  }

  static Future<List<dynamic>> checkIfUserIsAnArtist({int userId}) async {
    String url = baseUrl + 'verify_artist/$userId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      var res = jsonDecode(response.body);
      return res.length == 1 && res[0] == false ? null : res;
    } else {
      return null;
    }
  }

  static Future<bool> sendPushNotification(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'send_push_notification';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      return true;
    } else {
      return null;
    }
  }

  static Future<Song> createSong({@required Map<String, String> params}) async {
    String url = baseUrl + 'create_song';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      Map<String, dynamic> songMap = jsonDecode(response.body);
      return Song.fromJson(songMap);
    } else {
      return null;
    }
  }

  static Future<String> sendOtpPushNotification(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'send_otp_push_notification';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      Map<String, dynamic> res = getApiRes(response);
      return res['code'].toString();
    } else {
      return null;
    }
  }

  static Future<SongList> getSavedSongs(
      {@required int userId, String songList = '0'}) async {
    String url = songList != '0'
        ? baseUrl + 'get_songs/$songList'
        : baseUrl + 'get_saved_songs/$userId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      return SongList.fromSongMapList(res);
    } else {
      return SongList.fromSongMapList([]);
    }
  }

  static Future<SongList> getNewSongs(
      {@required int userId, String userLang, String genres}) async {
    String url = baseUrl + 'get_new_songs/$userId/$userLang/$genres';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      List<dynamic> res = json.decode(response.body);
      return SongList.fromSongMapList(res);
    } else {
      return SongList.fromSongMapList([]);
    }
  }

  static Future<Map<String, dynamic>> getAddressFromAddressId(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'extract_address_from_address_id/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<bool> changeUserLanguage(
      {@required int userId, @required String newLangCode}) async {
    String url = baseUrl + 'change_user_language/$userId/$newLangCode';
    Uri uri = Uri.parse(url);
    http.Response response = await https()
        .post(uri, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      Map<String, dynamic> res = json.decode(response.body);
      return res['was_language_changed'];
    } else {
      return null;
    }
  }

  static Future<bool> updateUserDevices(
      {@required int userId, @required String newDeviceToken}) async {
    String url = baseUrl + 'update_user_devices/$userId/$newDeviceToken';
    Uri uri = Uri.parse(url);
    http.Response response = await https()
        .post(uri, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<List<String>> createCustomer(Map<String, String> params) async {
    String url = baseUrl + 'create_customer/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return [response.body, response.statusCode.toString()];
  }

  static Future<bool> activateUserAccount(int userId) async {
    String url = baseUrl + 'set_user_account_to_active/$userId';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(
      uri,
      headers: getStandardHeaders(),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> activateAccountMap = json.decode(response.body);
      return activateAccountMap['account_is_set_to_active'];
    } else {
      return null;
    }
  }

  static Future<UserModel> sendOTPCode(
      {String email,
      String internationlPhoneNumber,
      @required String registrationType,
      @required String userName}) async {
    String url;
    if (registrationType == 'phone') {
      url = baseUrl +
          'send_otp_via_gloxonsms_or_sns/$internationlPhoneNumber/$userName';
    } else {
      url = baseUrl + 'send_otp_for_sigin/$email';
    }
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(
      uri,
      headers: getStandardHeaders(),
    );
    if (response.statusCode == 200) {
      final userModel = UserModel.fromJson(getApiRes(response));
      return userModel;
    } else {
      return null;
    }
  }

  static Future<UserModelProfile> getUserInfo(int userId,
      {int addReviews = 0}) async {
    String url = baseUrl + 'get_customer_profile/$addReviews/$userId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200) {
      Map<String, dynamic> result = getApiRes(response);
      return UserModelProfile.fromJson(result);
    } else {
      return null;
    }
  }

  static Future<ProductListForHomePage> getLikedAds(
      String adIds, String currencySymbol) async {
    if (adIds == null || adIds.isEmpty) {
      return null;
    }
    String url = baseUrl + 'get_liked_ads/$adIds';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getProductListForHomePage(response, currencySymbol);
  }

  static Future<ProductListForHomePage> getSimilarAdsTo(String currencySymbol,
      {Map<String, String> params}) async {
    String url = baseUrl + 'get_similar_ads';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getProductListForHomePage(response, currencySymbol);
  }

  static Future<AdsDetail> getAd(int adId, String currencySymbol) async {
    if (adId == null || adId < 1) {
      return null;
    }
    String url = baseUrl + 'get_ad/$adId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    if (response.statusCode == 200 && response.body.length > 50) {
      return AdsDetail.fromJson(getApiRes(response), currencySymbol);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> likeOrViewAd(int adId,
      {String whatToUpdate = 'number_of_views',
      int viewedOrLikedBy = 0}) async {
    whatToUpdate = whatToUpdate + 'T$viewedOrLikedBy';
    String url = baseUrl + 'like_or_view_ad/$adId/$whatToUpdate';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().post(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> incrementColumn(int idColumnValue,
      {String table = 'NewSongs',
      String idColumn = 'songId',
      String columnToIncrement = 'numberOfPlays'}) async {
    String url = baseUrl +
        'increment_a_column/$table/$columnToIncrement/$idColumnValue/$idColumn';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> createArtist(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'create_artist';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> updateProfile(
      {Map<String, String> params}) async {
    String url = baseUrl + 'update_profile_picture/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> sendReverificationCode(
      {Map<String, String> params}) async {
    String url = baseUrl + 'send_user_reverification_code';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<String> saveSocialProfilePictureUrl(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'save_social_profile_picture_url/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      return params['s3id'];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> saveOrUnsaveSong(
      {@required int songId, int userId, String action = 'save'}) async {
    String url = baseUrl + 'save_song/$songId/$userId/$action';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getApiRes(response);
  }

  static Future<ProductListForHomePage> getAdsInLocation(
      {@required double lat,
      @required double lng,
      @required String currencySymbol,
      @required String countryCode,
      int expandedSearch = 0,
      int startAdId = 0}) async {
    String url = baseUrl +
        'get_ads_in_location/$lat/$lng/$expandedSearch/$startAdId?country_code=$countryCode';
    Uri uri = Uri.parse(url);
    http.Response response = await https().get(
      uri,
      headers: getStandardHeaders(),
    );
    return getProductListForHomePage(response, currencySymbol);
  }

  static ProductListForHomePage getRecentlySavedHomePageAds(
      {@required String recentlySavedAds}) {
    if (recentlySavedAds != null) {
      return ProductListForHomePage.fromSavedAds(json.decode(recentlySavedAds));
    } else {
      return ProductListForHomePage(ads_details: []);
    }
  }

  static Future<ProductListForHomePage> adsInCategory(double lat, double lng,
      int categoryId, String currencySymbol, String countryCode) async {
    String url = baseUrl +
        'get_ads_in_category/$categoryId/$lat/$lng?country_code=$countryCode';
    Uri uri = Uri.parse(url);
    http.Response response = await https().get(
      uri,
      headers: getStandardHeaders(),
    );

    return getProductListForHomePage(response, currencySymbol);
  }

  static Future<ProductListForHomePage> getAdsFromSearchQuery(
      {@required double lat,
      @required double lng,
      @required String searchQuery,
      @required String currencySymbol,
      @required String countryCode}) async {
    String url = baseUrl +
        'get_ads_from_search_query/$lat/$lng/$searchQuery?country_code=$countryCode';
    Uri uri = Uri.parse(url);
    http.Response response = await https().get(
      uri,
      headers: getStandardHeaders(),
    );
    return getProductListForHomePage(response, currencySymbol);
  }

  static Future<ReviewData> checkUserHasReviewed(int userId, int adId) async {
    String url = baseUrl + 'check_if_user_has_reviewed_ad/$userId/$adId';
    Uri uri = Uri.parse(url);
    http.Response response = await https().get(
      uri,
      headers: getStandardHeaders(),
    );
    if (response.statusCode == 200) {
      return ReviewData.fromJson(getApiRes(response));
    } else {
      return null;
    }
  }

  static Future<int> postReview(Map<String, String> params,
      {bool isForApp = false}) async {
    String url =
        isForApp ? baseUrl + 'post_app_feedback/' : baseUrl + 'post_review/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = getApiRes(response);
      return isForApp ? responseBody['feedback_id'] : responseBody['review_id'];
    } else {
      return null;
    }
  }

  static Future<bool> createAd({@required Map<String, String> params}) async {
    String url = baseUrl + 'create_ad/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<bool> updateAd({@required Map<String, String> params}) async {
    String url = baseUrl + 'update_ad/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return response.statusCode == 200;
  }

  static Future<bool> updateProfileField(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'update_profile_field/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    if (response.statusCode == 200) {
      Map<String, dynamic> map = json.decode(response.body);
      return map['was_update_successful'];
    } else {
      return false;
    }
  }

  static Future<Map<String, dynamic>> sendEmailToUsers(
      {@required Map<String, String> params}) async {
    String url = baseUrl + 'send_email_to_users';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<String> postAnAudio(
      {@required String fileName,
      @required String audioFilePath,
      bool getUrl = false}) async {
    String url = baseUrl + 'post_an_audio/$fileName';
    var formData = FormData.fromMap(
        {'audio': await MultipartFile.fromFile(audioFilePath)});

    Dio dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    dio.options.baseUrl = url;
    dio.options.headers['header'] = getStandardHeaders()['header'];
    final response = await dio.post(url, data: formData);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseMap = response.data;
      return getUrl ? responseMap['url'] : responseMap['filename'];
    } else {
      return null;
    }
  }

  static Future<String> postAnImage(
      {@required String fileName,
      @required String imageFilePath,
      String imageType = 'ad',
      String isFirstImage = 'no',
      bool getUrl = false}) async {
    String url = baseUrl + 'post_an_image/$imageType/$isFirstImage/$fileName';
    var formData = FormData.fromMap(
        {'image': await MultipartFile.fromFile(imageFilePath)});

    Dio dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    dio.options.baseUrl = url;
    dio.options.headers['header'] = getStandardHeaders()['header'];
    final response = await dio.post(url, data: formData);
    if (response.statusCode == 200) {
      Map<String, dynamic> responseMap = response.data;
      return getUrl ? responseMap['url'] : responseMap['image_name'];
    } else {
      return null;
    }
  }

  static Future<String> postAnImageToS3(
      {@required String fileName,
      @required String imageFilePath,
      @required Map<String, dynamic> fields,
      @required String url}) async {
    var formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFilePath, filename: fileName),
      'fields': fields
    });

    Dio dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    File image = File(imageFilePath);
    dio.options.baseUrl = url;
    await dio.put(
      url,
      data: image.openRead(),
      options: Options(
        contentType: "image/jpeg",
        headers: {
          "Content-Length": image.lengthSync(),
        },
      ),
      onSendProgress: (int sentBytes, int totalBytes) {
        double progressPercent = sentBytes / totalBytes * 100;
      },
    );

    final response = await dio.put(url, data: formData);
    if (response.statusCode == 204) {
      return response.statusCode.toString();
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> deleteAnImage(
      {@required String fileName, String imageType = 'ad'}) async {
    Map<String, String> params = {
      'object_name': fileName,
      'object_type': imageType
    };
    String url = baseUrl + 'delete_an_s3_object/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<ProductListForHomePage> getUsersAds(
      String userId, String currencySymbol) async {
    String url = baseUrl + 'get_ads_created_by_user_id/$userId';
    Uri uri = Uri.parse(url);
    http.Response response =
        await https().get(uri, headers: getStandardHeaders());
    return getProductListForHomePage(response, currencySymbol);
  }

  static Future<Map<String, dynamic>> markAdAsSoldDeletedOrExpired(
      Map<String, String> params) async {
    String url = baseUrl + 'mark_ad_as_sold_or_deleted_or_expired/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> deactivateAccount(
      Map<String, String> params) async {
    String url = baseUrl + 'delete_customers_account/';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }

  static Future<Map<String, dynamic>> sendContactUsEmail(
      Map<String, String> params) async {
    String url = baseUrl + 'send_contactus_emails';
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri,
        body: params, headers: getStandardHeaders(isPostRequest: true));
    return getApiRes(response);
  }
}
