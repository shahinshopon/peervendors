import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';

class FormValidators {
  static bool isAValidEmail(String email) {
    email = email.trim();
    bool isEmailValid =
        email != null && email.length >= 5 && EmailValidator.validate(email);
    if (isEmailValid) {
      String topLevelDomain = email.split('.').last;
      isEmailValid = topLevelDomain.length > 1;
      return isEmailValid;
    }
    return isEmailValid;
  }

  static String trimLeft0(String number) {
    if (number == null || number.length < 7) {
      return '';
    }
    number = number.trim();
    return number.startsWith('0') ? number.substring(1) : number;
  }

  static bool isAnInteger(String string) => int.tryParse(string) != null;

  static String isAValidFullName(String name) {
    if (name == null || name.isEmpty) {
      return 'Enter your full name/votre nom';
    } else if (!RegExp(r"^[a-z]{2,15}( [a-z]{2,15}){1,3}$")
        .hasMatch(name.toLowerCase().trim())) {
      return "Enter valid name";
    }
    return null;
  }

  static String isOtpValid(String otpCode) {
    if (otpCode == null || otpCode.isEmpty) {
      return "Enter your 6 digit code";
    }
    if (!isAnInteger(otpCode)) {
      return "Only numbers are allowed";
    }
    int numCharsLeft = 6 - otpCode.length;
    if (numCharsLeft < 6 && numCharsLeft > 0) {
      return "$numCharsLeft more characters remaining.";
    }
    return null;
  }

  static String isValidPhoneNumber(
      {@required String phoneNumber, @required String phoneRegex}) {
    if (phoneNumber == null ||
        phoneNumber.isEmpty ||
        phoneNumber.length <= 6 ||
        !RegExp(phoneRegex).hasMatch(phoneNumber)) {
      return 'invalid';
    }
    return null;
  }

  static String getFirstImage({@required dynamic concatinatedImages}) {
    String images = concatinatedImages.toString();
    return images.split('|').first;
  }
}
