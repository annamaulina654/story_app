import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/screens/add_story_page.dart';
import 'package:story_app/screens/feed_page.dart';
import 'package:story_app/screens/login_page.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int currentIndex = 2;
  bool _isLoading = false;
  String? _profileErrorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  Future<bool> _isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _checkInitialConnectivity() async {
    setState(() {
      _isLoading = true;
      _profileErrorMessage = null;
    });

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      setState(() {
        _profileErrorMessage = 'No internet connection. Please check your network.';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) async {
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
    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No internet connection. Cannot log out.'),
          backgroundColor: AppColors.redError,
        ),
      );
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
    if (_profileErrorMessage != null || _isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot log out: No internet connection or page is loading.'),
          backgroundColor: AppColors.darkGrey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.darkGrey),
            ),
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
    Size size = MediaQuery.of(context).size;
    final currentUser = _auth.currentUser;
    String username = currentUser?.email?.split('@')[0] ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: (_profileErrorMessage != null || _isLoading) ? null : _showLogoutConfirmationDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading && _profileErrorMessage == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _profileErrorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.darkGrey, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          _profileErrorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.darkGrey, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            _checkInitialConnectivity();
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
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage('assets/images/user-profile.png'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentUser?.email ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'A storyteller with a love for quiet moments and bold dreams.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
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
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                  Text(
                    listOfLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: size.width * .01),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}