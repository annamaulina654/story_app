import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/models/feed_item_data.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/services/story_service.dart';
import 'package:story_app/services/permission_service.dart'; 

const String _kApiBaseUrl = 'http://localhost:3000';

class AddStoryPage extends StatefulWidget {
  final FeedItemData? initialStoryData;

  const AddStoryPage({super.key, this.initialStoryData});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _currentLocationName;
  String? _locationError;
  Position? _currentPosition;
  late final StoryService _storyService;
  late final PermissionService _permissionService; 

  @override
  void initState() {
    super.initState();
    _storyService = StoryService(_kApiBaseUrl);
    _permissionService = PermissionService(context); 
    if (widget.initialStoryData != null) {
      _descriptionController.text = widget.initialStoryData!.description;
      _currentLocationName = widget.initialStoryData!.location;
    }
    _determinePosition();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Layanan lokasi dinonaktifkan. Mohon aktifkan layanan lokasi.'),
        backgroundColor: AppColors.darkGrey));
      setState(() {
        _locationError = 'Layanan lokasi dinonaktifkan.';
      });
      return;
    }

    final hasPermission = await _permissionService.requestLocationPermission();
    if (!hasPermission) {
      setState(() {
        _locationError = 'Izin lokasi tidak diberikan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _locationError = null;
      _currentLocationName = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 30));
      setState(() {
        _currentPosition = position;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e'), backgroundColor: AppColors.redError),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentLocationName =
            '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        if (_currentLocationName!.trim().isEmpty) {
          _currentLocationName = 'Lat: ${position.latitude.toStringAsFixed(3)}, Lon: ${position.longitude.toStringAsFixed(3)}';
        }
      });
    } catch (e) {
      print('Error getting address from coordinates: $e');
      setState(() {
        _currentLocationName = 'Alamat tidak ditemukan';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await _permissionService.requestCameraPermission();
    } else { 
      hasPermission = await _permissionService.requestPhotosPermission();
    }

    if (!hasPermission) {
      return; 
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitStory() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deskripsi cerita tidak boleh kosong!'), backgroundColor: AppColors.darkGrey), 
      );
      return;
    }

    if (widget.initialStoryData == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon pilih gambar untuk cerita baru Anda!'), backgroundColor: AppColors.darkGrey), 
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login untuk mengunggah cerita.'), backgroundColor: AppColors.darkGrey), 
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String? base64Image;
    if (_selectedImage != null) {
      base64Image = base64Encode(_selectedImage!.readAsBytesSync());
    }

    try {
      if (widget.initialStoryData == null) {
        await _storyService.createStory(
          description: _descriptionController.text,
          location: _currentLocationName,
          firebaseUid: user.uid,
          mediaData: base64Image!, 
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cerita berhasil diunggah!'),
            backgroundColor: AppColors.greenSuccess, 
          ),
        );
      } else {
        await _storyService.updateStory(
          storyId: widget.initialStoryData!.id, 
          description: _descriptionController.text,
          location: _currentLocationName,
          firebaseUid: user.uid,
          mediaData: base64Image, 
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cerita berhasil diupdate!'),
            backgroundColor: AppColors.greenSuccess, 
          ),
        );
      }
      Navigator.of(context).pop(true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ${widget.initialStoryData == null ? 'mengunggah' : 'mengupdate'} cerita: ${e.toString()}'),
          backgroundColor: AppColors.redError, 
        ),
      );
      print('Error submitting story: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.initialStoryData == null ? 'Tambah Cerita Baru' : 'Edit Cerita';
    final String submitButtonText = widget.initialStoryData == null ? 'Unggah Cerita' : 'Simpan Perubahan';
     const double imageHeight = 300;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue, 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container( 
              height: imageHeight, 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200], 
                border: Border.all(color: AppColors.greyishBlue),
              ),
              child: _selectedImage != null
                  ? ClipRRect( 
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: imageHeight,
                      ),
                    )
                  : (widget.initialStoryData != null && widget.initialStoryData!.photoUrl.isNotEmpty
                      ? ClipRRect( 
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.initialStoryData!.photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: imageHeight,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: AppColors.darkGrey),
                                      SizedBox(height: 10),
                                      Text('Gambar tidak bisa dimuat', style: TextStyle(color: AppColors.darkGrey)),
                                    ],
                                  ),
                                ),
                          ),
                        )
                      : Center( 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/image-upload-bro.png',
                                width: 250, 
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                              const Text('Pilih atau ambil gambar', style: TextStyle(color: AppColors.greyishBlue)),
                            ],
                          ),
                        )),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( 
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12), 
                    ),
                  ),
                ),
                const SizedBox(width: 16), 
                Expanded( 
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12), 
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Deskripsi Cerita',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greyishBlue), 
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2), 
                ),
              ),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primaryBlue), 
                        SizedBox(width: 10),
                        Text('Lokasi Cerita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)), 
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading && _currentLocationName == null && _locationError == null)
                      Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)) 
                    else if (_locationError != null)
                      Text(
                        'Error mendapatkan lokasi: $_locationError',
                        style: TextStyle(color: AppColors.redError, fontSize: 14), 
                      )
                    else if (_currentLocationName != null)
                      Text(
                        'Lokasi: $_currentLocationName',
                        style: const TextStyle(fontSize: 16, color: AppColors.greyishBlue), 
                      )
                    else
                      const Text(
                        'Mendapatkan lokasi...',
                        style: TextStyle(fontSize: 16, color: AppColors.greyishBlue), 
                      ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _determinePosition,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Lokasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBlue, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitStory,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: _isLoading
                    ? const Text('Memproses...', style: TextStyle(color: Colors.white, fontSize: 18))
                    : Text(submitButtonText, style: const TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}