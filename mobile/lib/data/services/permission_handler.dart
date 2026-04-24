import 'dart:io';

import 'package:autism_care_management_application/common/widgets/yes_no_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHandler {
  // ================== LOCATION PERMISSION ==================
  Future<bool> requestLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      debugPrint("Location permission already granted");
      return true;
    }

    if (status.isDenied) {
      status = await Permission.location.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied) {
      return await _handlePermanentDenial(
        context,
        permissionName: "Location",
        featureDescription: "show nearby places and distance calculations",
      );
    }

    return false;
  }

  // ================== STORAGE PERMISSION ==================
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13+ uses PHOTOS permission instead of STORAGE
      return await _requestPhotosPermission(context);
    }

    var status = await Permission.storage.status;

    if (status.isGranted) {
      debugPrint("Storage permission already granted");
      return true;
    }

    if (status.isDenied) {
      status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied) {
      return await _handlePermanentDenial(
        context,
        permissionName: "Storage",
        featureDescription: "save and access files on your device",
      );
    }

    return false;
  }

  // ================ PHOTOS PERMISSION (Android 13+) ================
  Future<bool> _requestPhotosPermission(BuildContext context) async {
    var status = await Permission.photos.status;

    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.photos.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied) {
      return await _handlePermanentDenial(
        context,
        permissionName: "Photos",
        featureDescription: "access media files for uploads and downloads",
      );
    }

    return false;
  }

  // ================ COMMON PERMANENT DENIAL HANDLER ================
  Future<bool> _handlePermanentDenial(
    BuildContext context, {
    required String permissionName,
    required String featureDescription,
  }) async {
    final shouldOpenSettings = await showYesNoDialog(
      context: context,
      title: "$permissionName Permission Required",
      message: "To $featureDescription, please enable "
          "$permissionName permission in app settings.",
      positiveButton: "Open Settings",
      negativeButton: "Not Now",
      icon: Icons.settings,
    );

    if (shouldOpenSettings == true) {
      await openAppSettings();
      // Re-check after returning from settings
      return await Permission.location.isGranted;
    }

    return false;
  }
}
