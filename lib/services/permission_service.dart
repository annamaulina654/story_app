import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart'; 

class PermissionService {
  final BuildContext context; 

  PermissionService(this.context);

  Future<bool> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _showSnackBar('Location permission denied, please grant location permission.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Location permission permanently denied. Please open app settings.');
      openAppSettings();
      return false;
    }
    return false;
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _showSnackBar('Camera permission denied.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Camera permission permanently denied. Please open app settings.');
      openAppSettings();
      return false;
    }
    return false;
  }

  Future<bool> requestPhotosPermission() async {
    var status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _showSnackBar('Gallery permission denied.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Gallery permission permanently denied. Please open app settings.');
      openAppSettings();
      return false;
    }
    return false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, 
      ),
    );
  }
}