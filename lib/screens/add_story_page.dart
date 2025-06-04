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
  bool _useLocation = true; 


  @override
  void initState() {
    super.initState();
    _storyService = StoryService(_kApiBaseUrl);
    _permissionService = PermissionService(context); 
    if (widget.initialStoryData != null) {
      _descriptionController.text = widget.initialStoryData!.description;
      _currentLocationName = widget.initialStoryData!.location;
    }
    if (_useLocation) {
      _determinePosition();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    if (!_useLocation) {
      setState(() {
        _currentLocationName = null;
        _currentPosition = null;
        _locationError = null;
      });
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Location services disabled. Please enable location services.'),
          backgroundColor: AppColors.darkGrey));
      setState(() {
        _locationError = 'Location services disabled.';
      });
      return;
    }

    final hasPermission = await _permissionService.requestLocationPermission();
    if (!hasPermission) {
      setState(() {
        _locationError = 'Location permission not granted.';
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
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e'), backgroundColor: AppColors.redError),
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
      setState(() {
        _currentLocationName = 'Address not found';
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
        SnackBar(content: Text('Story description cannot be empty!'), backgroundColor: AppColors.darkGrey), 
      );
      return;
    }

    if (widget.initialStoryData == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image for your new story!'), backgroundColor: AppColors.darkGrey), 
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to upload a story.'), backgroundColor: AppColors.darkGrey), 
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
      final String? locationToSend = _useLocation ? _currentLocationName : null;
      final double? latitudeToSend = _useLocation ? _currentPosition?.latitude : null;
      final double? longitudeToSend = _useLocation ? _currentPosition?.longitude : null;


      if (widget.initialStoryData == null) {
        await _storyService.createStory(
          description: _descriptionController.text,
          location: locationToSend, 
          firebaseUid: user.uid,
          mediaData: base64Image!,
          latitude: latitudeToSend, 
          longitude: longitudeToSend, 
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Story uploaded successfully!'),
            backgroundColor: AppColors.greenSuccess,
          ),
        );
      } else {
        await _storyService.updateStory(
          storyId: widget.initialStoryData!.id,
          description: _descriptionController.text,
          location: locationToSend,
          firebaseUid: user.uid,
          mediaData: base64Image,
          latitude: latitudeToSend,
          longitude: longitudeToSend,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Story updated successfully!'),
            backgroundColor: AppColors.greenSuccess,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${widget.initialStoryData == null ? 'upload' : 'update'} story: ${e.toString()}'),
          backgroundColor: AppColors.redError,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.initialStoryData == null ? 'Add New Story' : 'Edit Story';
    final String submitButtonText = widget.initialStoryData == null ? 'Upload Story' : 'Save Changes';
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
                                      Text('Image failed to load.', style: TextStyle(color: AppColors.darkGrey)),
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
                              const Text('Choose or take image', style: TextStyle(color: AppColors.greyishBlue)),
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
                    label: const Text('Gallery'),
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
                    label: const Text('Camera'),
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
                labelText: 'Story Description',
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
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Use Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                ),
                Switch(
                  value: _useLocation,
                  onChanged: (bool newValue) {
                    setState(() {
                      _useLocation = newValue;
                      if (_useLocation) {
                        _determinePosition(); 
                      } else {
                        _currentLocationName = null;
                        _currentPosition = null;
                        _locationError = null;
                      }
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_useLocation)
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
                          Text('Story Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                          Spacer(), 
                          IconButton(
                            icon: Icon(Icons.refresh, color: AppColors.primaryBlue, size: 24),
                            onPressed: _isLoading ? null : _determinePosition,
                            tooltip: 'Refresh Location', 
                            padding: EdgeInsets.zero, 
                            constraints: BoxConstraints(),
                            visualDensity: VisualDensity.compact, 
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading && _currentLocationName == null && _locationError == null)
                        Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                      else if (_locationError != null)
                        Text(
                          'Error getting location: $_locationError',
                          style: TextStyle(color: AppColors.redError, fontSize: 14),
                        )
                      else if (_currentLocationName != null)
                        Text(
                          'Location: $_currentLocationName',
                          style: const TextStyle(fontSize: 16, color: AppColors.greyishBlue),
                        )
                      else
                        const Text(
                          'Getting location...',
                          style: TextStyle(fontSize: 16, color: AppColors.greyishBlue),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(submitButtonText, style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}