import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/main.dart';
import 'package:story_app/models/feed_item_data.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/services/story_service.dart';
import 'package:story_app/services/permission_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const String _kApiBaseUrl = 'http://localhost:3000/api';

class AddStoryPage extends StatefulWidget {
  final FeedItemData? initialStoryData;

  const AddStoryPage({super.key, this.initialStoryData});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _selectedImageFile;
  bool _isPageLoading = false;
  bool _isLocationLoading = false;
  String? _currentLocationName;
  String? _locationError;
  Position? _currentPosition;
  late final StoryService _storyService;
  late final PermissionService _permissionService;
  bool _useLocation = true;
  String? _addStoryErrorMessage;
  bool _isSubmittingStory = false;

  @override
  void initState() {
    super.initState();
    _storyService = StoryService(_kApiBaseUrl, supabase);
    _permissionService = PermissionService(context);

    _checkInitialConnectivityAndLoadData();

    if (widget.initialStoryData != null) {
      _descriptionController.text = widget.initialStoryData!.description;
      _currentLocationName = widget.initialStoryData!.location;
      _useLocation = widget.initialStoryData!.location != null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _checkInitialConnectivityAndLoadData() async {
    setState(() {
      _isPageLoading = true;
      _addStoryErrorMessage = null;
    });

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      setState(() {
        _addStoryErrorMessage =
            'No internet connection. Please check your network.';
        _isPageLoading = false;
      });
    } else {
      setState(() {
        _isPageLoading = false;
      });
      if (_useLocation) {
        _determinePosition();
      }
    }
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

    setState(() {
      _isLocationLoading = true;
      _locationError = null;
      _currentLocationName = null;
    });

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      setState(() {
        _locationError = 'Cannot get location: No internet connection.';
        _currentLocationName = null;
        _currentPosition = null;
        _isLocationLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection. Cannot get location.'),
            backgroundColor: AppColors.redError,
          ),
        );
      }
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location services disabled. Please enable location services.',
            ),
            backgroundColor: AppColors.darkGrey,
          ),
        );
      }
      setState(() {
        _locationError = 'Location services disabled.';
        _isLocationLoading = false;
      });
      return;
    }

    final hasPermission = await _permissionService.requestLocationPermission();
    if (!hasPermission) {
      setState(() {
        _locationError = 'Location permission not granted.';
        _isLocationLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      setState(() {
        _currentPosition = position;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppColors.redError,
          ),
        );
      }
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentLocationName =
            '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        if (_currentLocationName!.trim().isEmpty) {
          _currentLocationName =
              'Lat: ${position.latitude.toStringAsFixed(3)}, Lon: ${position.longitude.toStringAsFixed(3)}';
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
        _selectedImageFile = pickedFile;
      });
    }
  }

  Future<void> _submitStory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.initialStoryData == null && _selectedImageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select an image for your new story!'),
            backgroundColor: AppColors.darkGrey,
          ),
        );
      }
      return;
    }

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection. Cannot upload/update story.'),
            backgroundColor: AppColors.redError,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingStory = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in to upload a story.'),
            backgroundColor: AppColors.darkGrey,
          ),
        );
      }
      setState(() {
        _isSubmittingStory = false;
      });
      return;
    }

    try {
      final String? locationToSend = _useLocation ? _currentLocationName : null;
      final double? latitudeToSend = _useLocation ? _currentPosition?.latitude : null;
      final double? longitudeToSend = _useLocation ? _currentPosition?.longitude : null;

      if (widget.initialStoryData == null) {
        await _storyService.createStory(
          description: _descriptionController.text.trim(),
          location: locationToSend,
          firebaseUid: user.uid,
          mediaFile: _selectedImageFile!,
          latitude: latitudeToSend,
          longitude: longitudeToSend,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Story uploaded successfully!'),
              backgroundColor: AppColors.greenSuccess,
            ),
          );
        }
      } else {
        await _storyService.updateStory(
          storyId: widget.initialStoryData!.id,
          description: _descriptionController.text.trim(),
          location: locationToSend,
          firebaseUid: user.uid,
          mediaFile: _selectedImageFile,
          oldImageUrl: widget.initialStoryData!.photoUrl,
          latitude: latitudeToSend,
          longitude: longitudeToSend,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Story updated successfully!'),
              backgroundColor: AppColors.greenSuccess,
            ),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${widget.initialStoryData == null ? 'upload' : 'update'} story: ${e.toString()}',
            ),
            backgroundColor: AppColors.redError,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmittingStory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle =
        widget.initialStoryData == null ? 'Add New Story' : 'Edit Story';
    final String submitButtonText =
        widget.initialStoryData == null ? 'Upload Story' : 'Save Changes';
    const double imageHeight = 300;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isPageLoading && _addStoryErrorMessage == null
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : _addStoryErrorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.darkGrey,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _addStoryErrorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            _checkInitialConnectivityAndLoadData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          child: _selectedImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_selectedImageFile!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: imageHeight,
                                  ),
                                )
                              : (widget.initialStoryData != null &&
                                      widget.initialStoryData!.photoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        widget.initialStoryData!.photoUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: imageHeight,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: AppColors.darkGrey,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Image failed to load.',
                                                style: TextStyle(
                                                  color: AppColors.darkGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/image-upload-bro.png',
                                            width: 250,
                                            height: 250,
                                            fit: BoxFit.cover,
                                          ),
                                          const Text(
                                            'Choose or take image',
                                            style: TextStyle(
                                              color: AppColors.greyishBlue,
                                            ),
                                          ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                              borderSide: const BorderSide(
                                color: AppColors.greyishBlue,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                width: 1,
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                width: 2,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.multiline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Story description cannot be empty!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Use Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGrey,
                              ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryBlue,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Story Location',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.refresh,
                                          color: AppColors.primaryBlue,
                                          size: 24,
                                        ),
                                        onPressed: _isLocationLoading
                                            ? null
                                            : _determinePosition,
                                        tooltip: 'Refresh Location',
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_isLocationLoading)
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryBlue,
                                      ),
                                    )
                                  else if (_locationError != null)
                                    Text(
                                      'Error getting location: $_locationError',
                                      style: TextStyle(
                                        color: AppColors.redError,
                                        fontSize: 14,
                                      ),
                                    )
                                  else if (_currentLocationName != null)
                                    Text(
                                      'Location: $_currentLocationName',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.greyishBlue,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Getting location...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.greyishBlue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmittingStory || _isPageLoading
                                ? null
                                : _submitStory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmittingStory
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    submitButtonText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}