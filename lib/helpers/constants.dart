import 'package:flutter/material.dart';

class Constants {
  static const String defaulProfilePicture = 'default_profile_picture.jpg';
  static const String imageBaseUrl =
      'https://pvendors.s3.eu-west-3.amazonaws.com/prod_ad_images/';
  static const String imageBaseUrlCategories =
      'https://peervendors.s3.amazonaws.com/CategoryImages/';
  static const String imageBaseUrlSubCategories =
      'https://peervendors.s3.amazonaws.com/SubCategoryImages/';
  static const String peerVendorsAccountStatus = 'peerVendorsAccountStatus';
  static const String peerVendorsCurrencySymbol = 'peerVendorsCurrencySymbol';
  static const String peerVendorsCurrentAddress = 'peerVendorsCurrentAddress';
  static const String peerVendorsArtistStatus = 'peerVendorsArtistStatus';
  static const String peerVendorsCheckForUpdates = 'peerVendorsCheckForUpdates';
  static const String peerVendorsSavedSongsStatus =
      'peerVendorsSavedSongsStatus';
  static const String whenAddresLastRequested = "whenAddresLastRequested";
  static const String peerVendorsLanguage = 'peerVendorsLanguage';
  static const String peerVendorsArtistInfo = 'peerVendorsArtistInfo';
  static const String peerVendorsUserSongs = 'peerVendorsSongs';
  static const String peerVendorsWhenNewSongsVedSaved =
      'peerVendorsWhenNewSongsVedSaved';
  static const String peerVendorsNewSongs = 'peerVendorsNewSongs';
  static const String peerVendorsSavedSongs = 'peerVendorsSavedSongs';
  static const String peerVendorsOnboardingCompleted =
      'peerVendorsOnboardingCompleted';
  static const String peerVendorsRecentlySavedAds =
      'peerVendorsRecentlySavedAds';
  static const String peerVendorsFavorits = 'peerVendorsFavorits';
  static const String peerVendorsViews = 'peerVendorsViews';
  static const String peerVendorsReviews = 'peerVendorsReviews';
  static const String peerVendorsUser = 'peerVendorsUser';
  static const String profileImagesBaseUrl =
      'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/';
  static const String whenHomePageAdsWereExtracted =
      'whenHomePageAdsWereExtracted';
  static const String whenLastVerificationCodeWasSent =
      'whenLastVerificationCodeWasSent';
  static const String peerVendorsLastVCodes = 'peerVendorsLastVCodes';
  static Map<String, Map<String, dynamic>> countryLookupMap = {
    "BF": {
      "country_name": "Burkina Faso",
      "currency_symbol": "CFA",
      "dial_code": "+226",
      "mobile_phone_regex_pattern": r"^[2-7][0-9]{7,7}$",
      "flag": "assets/flags/bf.png"
    },
    "BJ": {
      "country_name": "Benin",
      "currency_symbol": "CFA",
      "dial_code": "+229",
      "mobile_phone_regex_pattern": r"^(21|22|23)?(4|6|9)[0-9]{7,7}$",
      "flag": "assets/flags/bj.png"
    },
    "BW": {
      "country_name": "Bostwana",
      "currency_symbol": "P",
      "dial_code": "+267",
      "mobile_phone_regex_pattern": r"^[2-9][0-9]{6,8}$",
      "flag": "assets/flags/bw.png"
    },
    "CM": {
      "country_name": "Cameroon",
      "currency_symbol": "CFA",
      "dial_code": "+237",
      "mobile_phone_regex_pattern": r"^6[4-9][0-9]{7,7}$",
      "flag": "assets/flags/cm.png"
    },
    "CA": {
      "country_name": "Canada",
      "currency_symbol": r"CA$",
      "dial_code": "+1",
      "mobile_phone_regex_pattern": r"^[2-9][0-9]{9,9}$",
      "flag": "assets/flags/ca.png"
    },
    "CV": {
      "country_name": "Cape Verde",
      "currency_symbol": r"$",
      "dial_code": "+238",
      "mobile_phone_regex_pattern": r"^[2-9][0-9]{6,6}$",
      "flag": "assets/flags/cv.png"
    },
    "EG": {
      "country_name": "Egypt",
      "currency_symbol": "E£",
      "dial_code": "+20",
      "mobile_phone_regex_pattern": r"^0?1(0|1|2|5)[0-9]{8,8}$",
      "flag": "assets/flags/eg.png"
    },
    "GA": {
      "country_name": "Gabon",
      "currency_symbol": "CFA",
      "dial_code": "+241",
      "mobile_phone_regex_pattern": r"^0[1-7][0-9]{6,7}$",
      "flag": "assets/flags/ga.png"
    },
    "GN": {
      "country_name": "Guinea",
      "currency_symbol": "FG",
      "dial_code": "+224",
      "mobile_phone_regex_pattern": r"^[1-9][0-9]{6,9}$",
      "flag": "assets/flags/gn.png"
    },
    "GW": {
      "country_name": "Guinea-Bissau",
      "currency_symbol": "CFA",
      "dial_code": "+245",
      "mobile_phone_regex_pattern": r"^(44|95|96|97)[1-9][0-9]{6,7}$",
      "flag": "assets/flags/gw.png"
    },
    "TD": {
      "country_name": "Chad",
      "currency_symbol": "CFA",
      "dial_code": "+235",
      "mobile_phone_regex_pattern": r"^0?22[5|6]([0-4]|[8|9])[0-9]{4,4}$",
      "flag": "assets/flags/td.png"
    },
    "CD": {
      "country_name": "Republic of the Congo",
      "currency_symbol": "CDF",
      "dial_code": "+243",
      "mobile_phone_regex_pattern": r"^0?(1|4)(|5|6)[0-9]{7,7}$",
      "flag": "assets/flags/cd.png"
    },
    "CG": {
      "country_name": "Congo Brazzaville",
      "currency_symbol": "CFA",
      "dial_code": "+242",
      "mobile_phone_regex_pattern": r"^0?[2-6][0-9]{8,8}$",
      "flag": "assets/flags/cg.png"
    },
    "CI": {
      "country_name": "Côte d'Ivoire",
      "currency_symbol": "CFA",
      "dial_code": "+225",
      "mobile_phone_regex_pattern": r"^0?[1245678][0-9]{7,11}$",
      "flag": "assets/flags/ci.png"
    },
    "ET": {
      "country_name": "Ethiopia",
      "currency_symbol": "Br",
      "dial_code": "+251",
      "mobile_phone_regex_pattern": r"^0?91[0-9]{7,7}$",
      "flag": "assets/flags/et.png"
    },
    "GH": {
      "country_name": "Ghana",
      "currency_symbol": "GH₵",
      "dial_code": "+233",
      "mobile_phone_regex_pattern": r"^0?(2|5)[0-9]{8,8}$",
      "flag": "assets/flags/gh.png"
    },
    "GM": {
      "country_name": "Gambia",
      "currency_symbol": "D",
      "dial_code": "+220",
      "mobile_phone_regex_pattern": r"^[1-9]{1,1}[0-9]{6,6}$",
      "flag": "assets/flags/gm.png"
    },
    "PK": {
      "country_name": "Pakistan",
      "currency_symbol": "Rs",
      "dial_code": "+92",
      "mobile_phone_regex_pattern": r"^0?3[0-9]{9,9}$",
      "flag": "assets/flags/pk.png"
    },
    "KE": {
      "country_name": "Kenya",
      "currency_symbol": "Ksh",
      "dial_code": "+254",
      "mobile_phone_regex_pattern": r"^0?(1|7)[0-9]{8,8}$",
      "flag": "assets/flags/ke.png"
    },
    "LR": {
      "country_name": "Liberia",
      "currency_symbol": r"L$",
      "dial_code": "+231",
      "mobile_phone_regex_pattern":
          r"^(555|886|888|880|886|770|776|777)[0-9]{6,7}$",
      "flag": "assets/flags/lr.png"
    },
    "MA": {
      "country_name": "Morocco",
      "currency_symbol": "DH",
      "dial_code": "+212",
      "mobile_phone_regex_pattern": r"^0?[5-8][0-9]{7,8}$",
      "flag": "assets/flags/ma.png"
    },
    "MG": {
      "country_name": "Madagascar",
      "currency_symbol": "MGA",
      "dial_code": "+261",
      "mobile_phone_regex_pattern": r"^0?3[0-9]{8,8}$",
      "flag": "assets/flags/mg.png"
    },
    "MW": {
      "country_name": "Malawi",
      "currency_symbol": "K",
      "dial_code": "+265",
      "mobile_phone_regex_pattern": r"^0?(77|88|99|21|0?1)[0-9]{6,7}$",
      "flag": "assets/flags/mw.png"
    },
    "ML": {
      "country_name": "Mali",
      "currency_symbol": "CFA",
      "dial_code": "+223",
      "mobile_phone_regex_pattern": r"^0?7(0|[3-9])[0-9]{6,6}$",
      "flag": "assets/flags/ml.png"
    },
    "NA": {
      "country_name": "Namibia",
      "currency_symbol": r"N$",
      "dial_code": "+264",
      "mobile_phone_regex_pattern": r"^0?(6|8)[0-9]{7,7}$",
      "flag": "assets/flags/na.png"
    },
    "NE": {
      "country_name": "Niger",
      "currency_symbol": "CFA",
      "dial_code": "+227",
      "mobile_phone_regex_pattern": r"^0?9(3|4|6)[0-9]{6,6}$",
      "flag": "assets/flags/ne.png"
    },
    "NG": {
      "country_name": "Nigeria",
      "currency_symbol": r"₦",
      "dial_code": "+234",
      "mobile_phone_regex_pattern": r"^0?[7-9][0-1][0-9]{8,9}$",
      "flag": "assets/flags/ng.png"
    },
    "RW": {
      "country_name": "Rwanda",
      "currency_symbol": "RWF",
      "dial_code": "+250",
      "mobile_phone_regex_pattern": r"^0?(783|788|75[0-9])[0-9]{6,6}$",
      "flag": "assets/flags/rw.png"
    },
    "TG": {
      "country_name": "Togo",
      "currency_symbol": "CFA",
      "dial_code": "+228",
      "mobile_phone_regex_pattern": r"^(2|7|9)[0-9]{7,7}$",
      "flag": "assets/flags/tg.png"
    },
    "TZ": {
      "country_name": "Tanzania",
      "currency_symbol": "TSh",
      "dial_code": "+255",
      "mobile_phone_regex_pattern": r"^0?(6|7)[0-9]{8,8}$",
      "flag": "assets/flags/tz.png"
    },
    "CF": {
      "country_name": "Central African Republic",
      "currency_symbol": "CFA",
      "dial_code": "+236",
      "mobile_phone_regex_pattern": r"^(2|7)[0-9]{7,7}$",
      "flag": "assets/flags/cf.png"
    },
    "ZA": {
      "country_name": "South Africa",
      "currency_symbol": "R",
      "dial_code": "+27",
      "mobile_phone_regex_pattern": r"^0?(6|7|8)[0-9]{7,7}$",
      "flag": "assets/flags/za.png"
    },
    "SD": {
      "country_name": "Sudan",
      "currency_symbol": "SDG",
      "dial_code": "+249",
      "mobile_phone_regex_pattern": r"^0?(90|91|92|93|95|96|99)[0-9]{7,7}$",
      "flag": "assets/flags/sd.png"
    },
    "SS": {
      "country_name": "South Sudan",
      "currency_symbol": "SSP",
      "dial_code": "+211",
      "mobile_phone_regex_pattern": r"^(91|92|95|97|12|1[6-9])[0-9]{7,7}$",
      "flag": "assets/flags/ss.png"
    },
    "SL": {
      "country_name": "Sierra Leone",
      "currency_symbol": "SL",
      "dial_code": "+232",
      "mobile_phone_regex_pattern":
          r"^0?(21|25|30|33|34|35|40|44|50|55|66|75|76|77|78|79|88)[0-9][0-9]{5,5}$",
      "flag": "assets/flags/sl.png"
    },
    "SO": {
      "country_name": "Somalia",
      "currency_symbol": "Sh.So",
      "dial_code": "+252",
      "mobile_phone_regex_pattern": r"^0?(6|9)[0-9]{8,8}$",
      "flag": "assets/flags/so.png"
    },
    "SN": {
      "country_name": "Senegal",
      "currency_symbol": "CFA",
      "dial_code": "+221",
      "mobile_phone_regex_pattern": r"^0?7[025678][0-9]{7,7}$",
      "flag": "assets/flags/sn.png"
    },
    "UG": {
      "country_name": "Uganda",
      "currency_symbol": "USh",
      "dial_code": "+256",
      "mobile_phone_regex_pattern": r"^0?7[0-9]{8,8}$",
      "flag": "assets/flags/ug.png"
    },
    "US": {
      "country_name": "United States",
      "currency_symbol": r"$",
      "dial_code": "+1",
      "mobile_phone_regex_pattern": r"^0?[2-9][0-9]{9,9}$",
      "flag": "assets/flags/us.png"
    },
    "ZM": {
      "country_name": "Zambia",
      "currency_symbol": "ZK",
      "dial_code": "+260",
      "mobile_phone_regex_pattern": r"^0?(95|96|97|76|77)[0-9]{7,7}$",
      "flag": "assets/flags/zm.png"
    },
    "ZW": {
      "country_name": "Zimbabwe",
      "currency_symbol": r"ZWL$",
      "dial_code": "+263",
      "mobile_phone_regex_pattern": r"^0?7(1|3|7|8)[0-9]{7,7}$",
      "flag": "assets/flags/zw.png"
    },
    "GQ": {
      "country_name": "Equatorial Guinea",
      "currency_symbol": r"GNF",
      "dial_code": "+240",
      "mobile_phone_regex_pattern": r"^(2|3|5|6|7)[1-9][0-9]{7,7}$",
      "flag": "assets/flags/gq.png"
    },
    "OT": {
      "country_name": "Other",
      "currency_symbol": r"$",
      "dial_code": "+555",
      "mobile_phone_regex_pattern": r"^0?[1-9][0-9]{7,12}$",
      "flag": "assets/flags/ot.png"
    }
  };

  static Map<String, dynamic> getCountryInfo({@required String countryCode}) {
    if (countryLookupMap.containsKey(countryCode)) {
      return countryLookupMap[countryCode];
    }
    return {
      "country_name": "Other",
      "currency_symbol": r"$",
      "dial_code": "+555",
      "mobile_phone_regex_pattern": r"^0?[1-9][0-9]{7,12}$",
      "flag": "assets/flags/ot.png"
    };
  }

  static String getLocalPhoneNumber(
      {@required String countryCode,
      @required String internationalPhoneNumber}) {
    for (var value in countryLookupMap.values) {
      if (internationalPhoneNumber.startsWith(value['dial_code'])) {
        return internationalPhoneNumber.replaceAll(value['dial_code'], '');
      }
    }
    return internationalPhoneNumber.replaceAll('+', '');
  }
}
