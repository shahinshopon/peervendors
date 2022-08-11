import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/io_client.dart';
//import 'package:geocoder/geocoder.dart' as geocoder;
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class Addresses {
  static IOClient https() {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  static Map<String, dynamic> getApiRes(http.Response response) {
    return response.statusCode == 200
        ? jsonDecode(utf8.decode(response.bodyBytes))
        : null;
  }

  static bool areLocationPermissionsAllowedGeolocation(
      LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static bool areLocationPermissionsAllowedLocation(
      loc.PermissionStatus permission) {
    return permission == loc.PermissionStatus.granted ||
        permission == loc.PermissionStatus.grantedLimited;
  }

  static Future<loc.LocationData> getLocationCoordinatesLocation() async {
    loc.Location location = loc.Location();
    loc.PermissionStatus _permissionStatus;
    loc.LocationData _locationData;

    try {
      _locationData = await location.getLocation();
      return _locationData;
    } catch (e) {
      _permissionStatus = await location.hasPermission();
      if (!areLocationPermissionsAllowedLocation(_permissionStatus)) {
        if (_permissionStatus == loc.PermissionStatus.deniedForever) {
          return null;
        } else {
          _permissionStatus = await location.requestPermission();
          if (!areLocationPermissionsAllowedLocation(_permissionStatus)) {
            return null;
          }
        }
      }
      _locationData = await location.getLocation();
      return _locationData;
    }
  }

  static Future<bool> getLocationPermissionsLocation() async {
    loc.Location location = loc.Location();
    loc.PermissionStatus _permissionStatus = await location.hasPermission();
    if (_permissionStatus == null ||
        !areLocationPermissionsAllowedLocation(_permissionStatus)) {
      // Location services are not enabled don't continue
      _permissionStatus = await location.requestPermission();
      return areLocationPermissionsAllowedLocation(_permissionStatus);
    } else {
      return true;
    }
  }

  static Future<bool> getLocationPermissionsGeolocation() async {
    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled == false) {
      // Location services are not enabled don't continue
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == null ||
        (!areLocationPermissionsAllowedGeolocation(permission) &&
            permission != LocationPermission.deniedForever)) {
      permission = await Geolocator.requestPermission();
      return permission == null
          ? null
          : areLocationPermissionsAllowedGeolocation(permission);
    } else {
      return true;
    }
  }

  static Future<Map<String, dynamic>> getBackendAddressFromLatLng(
      {@required double lat, @required double lng}) async {
    if (lat != null && lng != null) {
      String url =
          'https://www.peervendors.com/extract_address_id_from_lat_long/';
      Map<String, String> params = {
        'lng': lng.toString(),
        'lat': lat.toString()
      };
      Uri uri = Uri.parse(url);
      http.Response response = await https().post(uri, body: params, headers: {
        'accept': 'application/json',
        'header': "38ea57ca-f1a9-462c-a280-4eedfab0328b",
        'Content-Type': 'application/x-www-form-urlencoded'
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> addressMap = getApiRes(response);
        addressMap['lat'] = lat;
        addressMap['lng'] = lng;
        return addressMap;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getAddressFromBackend() async {
    Position geoposition;
    final String addressType = await isLocationServiceEnabled();
    if (addressType == "geolocation") {
      try {
        geoposition = await getCurrentUsersCoordinates();
      } catch (e) {
        bool permission = await getLocationPermissionsGeolocation();
        if (permission == true) {
          geoposition = await getCurrentUsersCoordinates();
          if (geoposition == null) {
            geoposition = await Geolocator.getLastKnownPosition();
          }
        }
      }
      if (geoposition != null) {
        Map<String, dynamic> addressData = await getBackendAddressFromLatLng(
            lat: geoposition.latitude, lng: geoposition.longitude);

        if (addressData != null) {
          return addressData;
        } else {
          Map<String, dynamic> placemarkAddress = await getAddressFromPlacemark(
              latitude: geoposition.latitude, longitude: geoposition.longitude);
          return placemarkAddress;
        }
      } else {
        return null;
      }
    } else if (addressType == "location") {
      loc.LocationData locationData = await getLocationCoordinatesLocation();
      if (locationData != null) {
        Map<String, dynamic> address = await getBackendAddressFromLatLng(
            lat: locationData.latitude, lng: locationData.longitude);
        if (address != null) {
          return address;
        } else {
          Map<String, dynamic> placemarkAddress = await getAddressFromPlacemark(
              latitude: locationData.latitude,
              longitude: locationData.longitude);
          return placemarkAddress;
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getCurrentAddressMap() async {
    Position geoposition;
    final String addressType = await isLocationServiceEnabled();
    if (addressType == "geolocation") {
      try {
        geoposition = await getCurrentUsersCoordinates();
      } catch (e) {
        bool permission = await getLocationPermissionsGeolocation();
        if (permission == true) {
          geoposition = await getCurrentUsersCoordinates();
          if (geoposition == null) {
            geoposition = await Geolocator.getLastKnownPosition();
          }
        }
      }
      if (geoposition != null) {
        Placemark placemarkAddress = await getGeocoderAddressFromLatLng(
            lat: geoposition.latitude, lng: geoposition.longitude);
        return cleanedPlacemark(placemarkAddress,
            lat: geoposition.latitude, lng: geoposition.longitude);
      } else {
        return null;
      }
    } else if (addressType == "location") {
      loc.LocationData locationData = await getLocationCoordinatesLocation();
      if (locationData != null) {
        Placemark placemarkAddress = await getGeocoderAddressFromLatLng(
            lat: locationData.latitude, lng: locationData.longitude);
        return cleanedPlacemark(placemarkAddress,
            lat: locationData.latitude, lng: locationData.longitude);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getAddressFromPlacemark(
      {double latitude, double longitude}) async {
    Placemark geocoderAddress =
        await getGeocoderAddressFromLatLng(lat: latitude, lng: longitude);
    Map<String, dynamic> cityStateCountryCode =
        getCityAndStateFromGeocoderAddress(geocoderAddress,
            lat: latitude, lng: longitude);
    if (cityStateCountryCode == null) {
      return null;
    } else {
      cityStateCountryCode['lng'] = longitude;
      cityStateCountryCode['lat'] = latitude;
      int addressId = await saveANewAddress(addressData: cityStateCountryCode);
      cityStateCountryCode['address_id'] = addressId;
      return cityStateCountryCode;
    }
  }

  static Future<int> saveANewAddress(
      {@required Map<String, dynamic> addressData}) async {
    String url = 'https://www.peervendors.com/save_a_new_address/';
    Map<String, String> params =
        addressData.map((key, value) => MapEntry(key, value?.toString()));
    Uri uri = Uri.parse(url);
    http.Response response = await https().post(uri, body: params, headers: {
      'accept': 'application/json',
      'header': "38ea57ca-f1a9-462c-a280-4eedfab0328b",
      'Content-Type': 'application/x-www-form-urlencoded'
    });
    if (response.statusCode == 200) {
      Map<String, dynamic> addressIdMap = getApiRes(response);
      return addressIdMap['address_id'];
    } else {
      return null;
    }
  }

  static Map<String, dynamic> cleanedPlacemark(Placemark placemark,
      {double lat, double lng}) {
    if (placemark == null) {
      return {};
    }
    Map<String, dynamic> lastAdInfo = Map.from(placemark.toJson())
      ..removeWhere((k, v) => v == null || v.isEmpty);
    if (lat != null) {
      lastAdInfo['lat'] = lat;
      lastAdInfo['lng'] = lng;
    }
    return lastAdInfo;
  }

  static String getKeyFromAddressMap(
      Map<String, dynamic> address, String keys, String keyType) {
    for (String key in keys.split(',')) {
      if (address.containsKey(key)) {
        return address[key];
      }
    }
    if (address.containsKey('name')) {
      List<String> addressParts = address['name'].split(', ');
      return keyType == 'city' ? addressParts.first : addressParts.last;
    }
    if (address.containsKey('street')) {
      return address['street'].split(', ').last;
    }
    return keyType;
  }

  static Map<String, dynamic> getCityAndStateFromGeocoderAddress(
      Placemark geocoderAddress,
      {double lat,
      double lng}) {
    if (geocoderAddress != null) {
      Map<String, dynamic> rawAddressMap =
          cleanedPlacemark(geocoderAddress, lat: lat, lng: lng);
      Map<String, dynamic> addressData = Map<String, dynamic>();
      addressData['state'] = getKeyFromAddressMap(
          rawAddressMap,
          'locality,subLocality,subAdministrativeArea,thoroughfare,subThoroughfare,administrativeArea',
          'city');
      addressData['city'] = getKeyFromAddressMap(
          rawAddressMap,
          'administrativeArea,subAdministrativeArea,locality,subLocality',
          'state');
      addressData['country_code'] =
          geocoderAddress.isoCountryCode.toUpperCase();
      return addressData;
    } else {
      return null;
    }
  }

  static Future<String> isLocationServiceEnabled() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (isLocationServiceEnabled != true) {
      loc.Location location = loc.Location();
      isLocationServiceEnabled = await location.serviceEnabled();
      if (isLocationServiceEnabled != true) {
        isLocationServiceEnabled = await location.requestService();
        return isLocationServiceEnabled != true ? null : "location";
      } else {
        return 'location';
      }
    } else {
      return 'geolocation';
    }
  }

  static void openLocSettings() async {
    try {
      Geolocator.openLocationSettings();
    } catch (e) {
      openAppSettings();
    }
  }

  static void openAppSettings() {
    openAppSettings();
  }

  static Future<Map<String, dynamic>> getUsersCurrentAddress(
      {int minTimeToWaitInSeconds = 15, bool isInternal = false}) async {
    if (isInternal) {
      return await getAddress();
    } else {
      bool serviceEnabled;
      LocationPermission permission;
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          return null;
        } else {
          return await getAddress();
        }
      } else {
        return await getAddress();
      }
    }
  }

  static Future<Position> getCurrentUsersCoordinates() async {
    Position geoposition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);
    if (geoposition != null) {
      return geoposition;
    } else {
      geoposition = await Geolocator.getLastKnownPosition();
      return geoposition;
    }
  }

  static Future<Map<String, dynamic>> getAddress() async {
    Position geoposition = await getCurrentUsersCoordinates();
    Map<String, dynamic> currentAddress = {};
    if (geoposition != null) {
      currentAddress = await getBackendAddressFromLatLng(
          lat: geoposition.latitude, lng: geoposition.longitude);
      return currentAddress;
    } else {
      return null;
    }
  }

  static Future<Placemark> getGeocoderAddressFromLatLng(
      {double lat, double lng}) async {
    if (lat == null || lng == null) {
      return null;
    } else {
      //Coordinates geopositionCoords = Coordinates(lat, lng);
      List<Placemark> addresses =
          await placemarkFromCoordinates(lat, lng, localeIdentifier: 'en-US');
      // List<Address> addresses =
      //     await Geocoder.local.findAddressesFromCoordinates(geopositionCoords);
      //Placemark t = addresses.first;
      // if(addresses == null || addresses.length == 0)
      // if (addresses.any((element) => element.subAdminArea != null)){
      //
      //}
      return addresses?.isEmpty == true ? null : addresses.first;
    }
  }
}
