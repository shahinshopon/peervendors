import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';

class AppVersion {
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int versionNumber = int.tryParse(packageInfo.buildNumber);
    if (versionNumber == null) {
      return packageInfo.version;
    }
    var pv = packageInfo.version.split('.');
    int numb = int.tryParse(pv.last);
    if (numb == null) {
      return packageInfo.version;
    }
    pv.last = (numb + versionNumber).toString();
    return pv.join('.');
  }
}
