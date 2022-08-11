import 'package:peervendors/helpers/constants.dart';

class UserModel {
  int address_id;
  String email;
  String last_verification_code;
  int user_id;
  String user_lang;
  String username;
  String phoneNumber;
  String firebaseUserId;
  String profilePicture;
  String currencySymbol;
  String country_code;
  String deviceIds;

  UserModel(
      {this.address_id,
      this.email,
      this.last_verification_code,
      this.user_id,
      this.user_lang,
      this.username,
      this.phoneNumber,
      this.firebaseUserId,
      this.profilePicture,
      this.currencySymbol,
      this.country_code,
      this.deviceIds});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String countryCode = json['country_code'];
    Map<String, dynamic> countryInfo =
        Constants.getCountryInfo(countryCode: countryCode);
    String currencySymbol =
        countryInfo == null ? r'$' : countryInfo['currency_symbol'];
    return UserModel(
        address_id: json['address_id'],
        email: json['email'],
        last_verification_code: json['last_verification_code'].toString(),
        user_id: json['user_id'],
        user_lang: json['user_lang'],
        username: json['username'],
        firebaseUserId: json['firebase_id'],
        phoneNumber: json['phone_number'],
        country_code: countryCode,
        profilePicture: json['profile_picture'],
        deviceIds: json['device_ids'],
        currencySymbol: currencySymbol);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['address_id'] = this.address_id;
    data['email'] = this.email;
    data['last_verification_code'] = this.last_verification_code;
    data['user_id'] = this.user_id;
    data['user_lang'] = this.user_lang;
    data['username'] = this.username;
    data['firebase_id'] = this.firebaseUserId;
    data['profile_picture'] = this.profilePicture;
    data['phone_number'] = this.phoneNumber;
    data['country_code'] = this.country_code;
    data['currencySymbol'] = this.currencySymbol;
    data['device_ids'] = this.deviceIds;
    return data;
  }

  static String getUpdatedDeviceIds(
      String newDeviceId, String currentUsersDeviceIds) {
    if (newDeviceId != null && !currentUsersDeviceIds.contains(newDeviceId)) {
      if (currentUsersDeviceIds == 'TOKEN_NOT_YET_PROVIDED') {
        return newDeviceId;
      } else {
        List<String> tokens = currentUsersDeviceIds.split('||!||');
        return tokens.length > 1
            ? '${tokens.last}||!||$newDeviceId'
            : '${tokens.first}||!||$newDeviceId';
      }
    } else {
      return currentUsersDeviceIds;
    }
  }
}
