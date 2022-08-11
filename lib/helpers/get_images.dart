import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class GetImages {
  static Future<List<dynamic>> getImageFile(
      ImagePicker imagePicker, ImageSource source,
      {String imageUseFor = 'ad',
      String isFirstImage = 'no',
      String cropMessage = "Edit your picture"}) async {
    var dims = getMaxDims(imageUseFor);
    String fileName = const Uuid().v4().toLowerCase();
    try {
      XFile pickedFile = await imagePicker.pickImage(
          source: source,
          maxWidth: dims[0],
          maxHeight: dims[1],
          imageQuality: 95);
      if (pickedFile == null) {
        final LostDataResponse response = await imagePicker.retrieveLostData();
        if (response == null || response.isEmpty || response.file == null) {
          return null;
        } else {
          pickedFile = response.file;
          File imageFile = File(pickedFile.path);
          return cropImage(imageFile, fileName,
              imageUseFor: imageUseFor,
              isFirstImage: isFirstImage,
              cropMessage: cropMessage);
        }
      } else {
        File imageFile = File(pickedFile.path);
        return cropImage(imageFile, fileName,
            imageUseFor: imageUseFor,
            isFirstImage: isFirstImage,
            cropMessage: cropMessage);
      }
    } catch (e) {
      if (source == ImageSource.gallery) {
        final filePaths =
            await selectMedia(allowMultiple: false, isPhoto: true);
        if (filePaths?.isNotEmpty == true) {
          File imageFile = File(filePaths.first);
          return cropImage(imageFile, fileName,
              imageUseFor: imageUseFor,
              isFirstImage: isFirstImage,
              cropMessage: cropMessage);
        }
      }
    }
  }

  static Future<List<String>> pickImageWithoutCropping(
      ImagePicker imagePicker, ImageSource source,
      {String imageUseFor = 'ad',
      String isFirstImage = 'no',
      String cropMessage = "Edit your picture"}) async {
    List dims = getMaxDims(imageUseFor);
    XFile pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: dims[0],
        maxHeight: dims[1],
        imageQuality: 95);
    if (pickedFile == null) {
      final LostDataResponse response = await imagePicker.retrieveLostData();
      return [response?.file?.path];
    } else {
      return [pickedFile.path];
    }
  }

  static List<double> getMaxDims(String useFor) {
    return useFor == 'ad' ? [1000, 1450] : [850, 1200];
  }

  static Future<List<String>> pickMultipleImages(ImagePicker imagePicker,
      {String imageUseFor = 'ad',
      String isFirstImage = 'no',
      String cropMessage = "Edit your picture"}) async {
    var dims = getMaxDims(imageUseFor);
    try {
      List<XFile> pickedFiles = await imagePicker.pickMultiImage(
          maxWidth: dims[0], maxHeight: dims[1], imageQuality: 95);
      if (pickedFiles == null) {
        final LostDataResponse response = await imagePicker.retrieveLostData();
        return response == null || response.isEmpty || response.files == null
            ? null
            : response.files.map((e) => e.path).toList();
      }
      return pickedFiles.map((f) => f.path).toList();
    } catch (e) {
      return await selectMedia(allowMultiple: true);
    }
  }

  static Future<String> pickVideo(
      ImageSource imageSource, int numberOfPermissions,
      {List<String> exts = const ['mp3', 'ogg', 'm4a', 'wav', 'aac']}) async {
    final ImagePicker _picker = ImagePicker();
    try {
      var pickedFile = await _picker.pickVideo(
          source: imageSource, maxDuration: const Duration(minutes: 8));
      if (pickedFile == null) {
        final LostDataResponse response = await _picker.retrieveLostData();
        String p = response?.file?.path;
        if (p != null) {
          return p;
        } else {
          return await selectVideo(imageSource, numberOfPermissions);
        }
      } else {
        return pickedFile.path;
      }
    } catch (e) {
      return await selectVideo(imageSource, numberOfPermissions);
    }
  }

  static Future<String> selectVideo(
      ImageSource imageSource, int numberOfPermissions) async {
    if (imageSource == ImageSource.gallery || numberOfPermissions == 2) {
      try {
        FilePickerResult f =
            await FilePicker.platform.pickFiles(type: FileType.video);
        return f?.files?.first?.path;
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<List<String>> selectMedia(
      {bool isPhoto = true, bool allowMultiple = false}) async {
    List<String> extensions =
        isPhoto ? ['jpg', 'jpeg', 'png'] : ['mp3', 'ogg', 'm4a', 'wav', 'aac'];
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: allowMultiple);
    if (allowMultiple) {
      return result?.paths;
    }
    return [result?.files?.single?.path];
  }

  static Future<List<dynamic>> cropImage(File imageFile, String fileName,
      {String imageUseFor = 'ad',
      String isFirstImage = 'no',
      String cropMessage = "Edit your picture"}) async {
    try {
      File croppedFile = await ImageCropper.cropImage(
          compressQuality: 98,
          sourcePath: imageFile.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: cropMessage,
              toolbarColor: Colors.indigoAccent[100],
              toolbarWidgetColor: Colors.white,
              statusBarColor: Colors.indigoAccent[100],
              initAspectRatio: CropAspectRatioPreset.square,
              cropGridRowCount: 0,
              cropGridColumnCount: 0,
              lockAspectRatio: false,
              hideBottomControls: true));
      if (croppedFile != null) {
        return [croppedFile, fileName];
      } else {
        return [imageFile, fileName];
      }
    } catch (e) {
      return [imageFile, fileName];
    }
  }
}
