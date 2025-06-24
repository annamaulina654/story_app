import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/main.dart';
import 'package:story_app/models/user_data.dart';
import 'package:story_app/services/profil_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfilePage({super.key, required this.userProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  
  File? _imageFile; 
  bool _isProfilePictureDeleted = false; 
  
  bool _isLoading = false;
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(supabase);
    _usernameController = TextEditingController(text: widget.userProfile.username);
    _fullNameController = TextEditingController(text: widget.userProfile.fullName);
    _bioController = TextEditingController(text: widget.userProfile.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Select from Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              if (widget.userProfile.profileImageUrl != null || _imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Profile Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _deleteProfilePicture();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isProfilePictureDeleted = false; 
      });
    }
  }

  void _deleteProfilePicture() {
    setState(() {
      _imageFile = null;
      _isProfilePictureDeleted = true;
    });
  }

  Future<void> _submitProfileUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? newImageUrl;
      final oldImageUrl = widget.userProfile.profileImageUrl; 

      if (_isProfilePictureDeleted) {
        await _profileService.deleteProfilePictureFromSupabase(oldImageUrl);
      } 
      else if (_imageFile != null) {
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _profileService.deleteProfilePictureFromSupabase(oldImageUrl);
        }
        
        newImageUrl = await _profileService.uploadProfileImage(_imageFile!, widget.userProfile.firebaseUid);
      }

      await _profileService.updateUserProfile(
        firebaseUid: widget.userProfile.firebaseUid,
        username: _usernameController.text,
        fullName: _fullNameController.text,
        bio: _bioController.text,
        newImageUrl: newImageUrl,
        isImageDeleted: _isProfilePictureDeleted,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  ImageProvider _getAvatarImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    if (_isProfilePictureDeleted || widget.userProfile.profileImageUrl == null || widget.userProfile.profileImageUrl!.isEmpty) {
      return const AssetImage('assets/images/user-profile.png');
    }
    return NetworkImage(widget.userProfile.profileImageUrl!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _getAvatarImage(),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryBlue,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) { return 'Full name cannot be empty'; }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) { return 'Username cannot be empty'; }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfileUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}