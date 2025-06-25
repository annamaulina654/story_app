import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/main.dart';
import 'package:story_app/screens/add_story_page.dart';
import 'package:story_app/screens/edit_profile_page.dart';
import 'package:story_app/screens/feed_page.dart';
import 'package:story_app/screens/login_page.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:story_app/models/user_data.dart';
import 'package:story_app/services/follow_service.dart';
import 'package:story_app/services/profil_service.dart';
import 'package:story_app/screens/user_story_feed_page.dart'; 
import 'package:story_app/screens/follows_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userFirebaseUid;

  const ProfilePage({super.key, this.userFirebaseUid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final ProfileService _profileService;
  UserProfile? _userProfile;

  int currentIndex = 2;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isCurrentUserProfile => widget.userFirebaseUid == null || widget.userFirebaseUid == _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(supabase);
    final targetUid = widget.userFirebaseUid ?? _auth.currentUser?.uid;
    if (targetUid != null) {
      _fetchProfileData(targetUid);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Users not found.";
      });
    }
  }

  Future<void> _fetchProfileData(String uid) async {
    if (_userProfile == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = 'No internet connection.';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await _profileService.fetchUserProfile(uid); // BENAR
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToFollowsPage(int initialIndex) async {
    if (_userProfile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowsPage(
          userFirebaseUid: _userProfile!.firebaseUid,
          username: _userProfile!.username,
          initialTabIndex: initialIndex,
        ),
      ),
    );

    if (result == true && mounted) {
      print("Reloading profile data...");
      _fetchProfileData(_userProfile!.firebaseUid);
    }
  }

  void _onItemTapped(int index) async {
    if (index == currentIndex) return;

    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedPage()),
      );
    } else if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddStoryPage()),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedPage()),
      );
    }
  }

  Future<void> _performLogout() async {
    final hasInternet = await Connectivity().checkConnectivity() != ConnectivityResult.none;
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection. Cannot log out.'),
            backgroundColor: AppColors.redError,
          ),
        );
      }
      return;
    }

    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: $e'),
            backgroundColor: AppColors.redError,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color:  Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Log out'),
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Credits'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This application was developed by:'),
            SizedBox(height: 12),
            Text('• Anna Maulina', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• Amalia Fitri Lestari', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• Shenny Nur Kholifah', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
            style: TextButton.styleFrom( foregroundColor: Colors.black )

          ),
        ],
      ),
    );
  }

  final List<IconData> listOfIcons = [
    Icons.feed,
    Icons.add_circle,
    Icons.person,
  ];

  final List<String> listOfLabels = [
    'Feed',
    'Add Story',
    'Profile',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile?.username ?? (isCurrentUserProfile ? 'Profile' : '')),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: isCurrentUserProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'Info',
                  onPressed: () => _showDeveloperInfoDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _showLogoutConfirmationDialog,
                ),
              ]
            : [],
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _errorMessage != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  child: _buildProfileContent(),
                ),
      ),
      bottomNavigationBar: isCurrentUserProfile ? _buildBottomNavBar(MediaQuery.of(context).size) : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.darkGrey, size: 50),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkGrey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final targetUid = widget.userFirebaseUid ?? _auth.currentUser!.uid;
                _fetchProfileData(targetUid);
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
    );
  }

  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return _buildErrorWidget();
    }
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 60,
          backgroundImage: _userProfile!.profileImageUrl != null && _userProfile!.profileImageUrl!.isNotEmpty
              ? NetworkImage(_userProfile!.profileImageUrl!)
              : const AssetImage('assets/images/user-profile.png') as ImageProvider,
        ),
        const SizedBox(height: 10),
        Text(
          _userProfile!.fullName ?? _userProfile!.username,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          '@${_userProfile!.username}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _userProfile!.bio ?? 'No bio yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: isCurrentUserProfile
              ? ElevatedButton(
                  onPressed: () async {
                    if (_userProfile == null) return;
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage(userProfile: _userProfile!)),
                    );
                    if (result == true) {
                      _fetchProfileData(_userProfile!.firebaseUid);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8CB0FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Edit Profile'),
                )
              : _FollowButton(
                  profileOwnerUid: _userProfile!.firebaseUid,
                  loggedInUserUid: _auth.currentUser!.uid,
                ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatColumn('Stories', _userProfile!.storyCount),
            const SizedBox(width: 40),
            _buildStatColumn(
              'Followers',
              _userProfile!.followerCount,
              onTap: () => _navigateToFollowsPage(0),
            ),
            const SizedBox(width: 40),
            _buildStatColumn(
              'Following',
              _userProfile!.followingCount,
              onTap: () => _navigateToFollowsPage(1),

            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(),
      
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: _userProfile!.stories.length,
          itemBuilder: (context, index) {
            final story = _userProfile!.stories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserStoryFeedPage(
                      stories: _userProfile!.stories, 
                      initialIndex: index,            
                    ),
                  ),
                );
              },
              child: Image.network(
                story.photoUrl, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
              ),
            );
          },
        ),
      ],
    );
  }

    Widget _buildStatColumn(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector( 
      onTap: onTap, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Size size) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: size.width * .155,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(listOfIcons.length, (index) {
          bool isSelected = index == currentIndex;
          return InkWell(
            onTap: () => _onItemTapped(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.fastLinearToSlowEaseIn,
                  margin: EdgeInsets.only(
                    bottom: isSelected ? 0 : size.width * .029,
                  ),
                  width: size.width * .128,
                  height: isSelected ? size.width * .014 : 0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                ),
                Icon(
                  listOfIcons[index],
                  size: size.width * .076,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                ),
                Text(
                  listOfLabels[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: size.width * .01),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String profileOwnerUid;
  final String loggedInUserUid;

  const _FollowButton({
    required this.profileOwnerUid,
    required this.loggedInUserUid,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  final FollowService _followService = FollowService(baseUrl: 'https://story-app-api-eta.vercel.app/api',
  notificationsPlugin: flutterLocalNotificationsPlugin,
  );
  bool? _isFollowing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final status = await _followService.isFollowing(
        followerUid: widget.loggedInUserUid,
        followedUid: widget.profileOwnerUid,
      );
      if (mounted) {
        setState(() {
          _isFollowing = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing == null) return;
    setState(() => _isLoading = true);

    try {
      if (_isFollowing!) {
        await _followService.unfollowUser(
          followerUid: widget.loggedInUserUid,
          followedUid: widget.profileOwnerUid,
        );
      } else {
        await _followService.followUser(
          followerUid: widget.loggedInUserUid,
          followedUid: widget.profileOwnerUid,
        );
      }
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing!);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 45,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isFollowing == null) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing! ? Colors.grey[200] : AppColors.primaryBlue,
        foregroundColor: _isFollowing! ? Colors.black87 : Colors.white,
        minimumSize: const Size.fromHeight(45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(_isFollowing! ? 'Following' : 'Follow'),
    );
  }
}