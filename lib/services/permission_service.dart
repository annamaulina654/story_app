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
      _showSnackBar('Izin lokasi ditolak, mohon berikan izin lokasi.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Izin lokasi ditolak secara permanen. Mohon buka pengaturan aplikasi.');
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
      _showSnackBar('Izin kamera ditolak.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Izin kamera ditolak secara permanen. Mohon buka pengaturan aplikasi.');
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
      _showSnackBar('Izin galeri ditolak.');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Izin galeri ditolak secara permanen. Mohon buka pengaturan aplikasi.');
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