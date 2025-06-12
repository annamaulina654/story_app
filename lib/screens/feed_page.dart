import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:story_app/screens/add_story_page.dart';
import 'package:story_app/screens/login_page.dart';
import 'package:story_app/widgets/feed_item.dart';
import 'package:story_app/models/feed_item_data.dart';
import 'package:story_app/services/story_service.dart';
import 'package:story_app/utils/dialog_utils.dart';
import 'package:story_app/constants/app_colors.dart'; 
import 'package:story_app/screens/profil_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


const String _kApiBaseUrl = 'http://localhost:3000/api';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  var currentIndex = 0;
  List<FeedItemData> _feedItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final StoryService _storyService;
  final FirebaseAuth _auth = FirebaseAuth.instance; 

  @override
  void initState() {
    super.initState();
    _storyService = StoryService(_kApiBaseUrl);
    _fetchStoriesFromBackend();
  }

  Future<bool> _isInternetAvailable() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
  }
  Future<void> _fetchStoriesFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network.';
        _isLoading = false;
      });
      return;
    }

    try {
      final List<FeedItemData> fetchedStories = await _storyService.fetchStories();
      setState(() {
        _feedItems = fetchedStories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
  }
}


  void _editPost(FeedItemData item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStoryPage(initialStoryData: item),
      ),
    ).then((result) {
      if (result == true) {
        _fetchStoriesFromBackend();
      }
    });
  }

  void _deletePost(FeedItemData item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to delete the story.'), backgroundColor: AppColors.darkGrey), 
      );
      return;
    }

    bool confirmDelete = await DialogUtils.showConfirmDeleteDialog(context);
    if (!confirmDelete) {
      return;
    }

    try {
      await _storyService.deleteStory(item.id.toString(), currentUser.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story deleted successfully!'), backgroundColor: AppColors.primaryBlue), 
      );
      setState(() {
        _feedItems.removeWhere((i) => i.id == item.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting story: $e'), backgroundColor: AppColors.darkGrey), 
      );
    }
  }

  void _followUser(String targetUserFirebaseUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to follow users.')),
      );
      return;
    }
    final followerFirebaseUid = currentUser.uid;

    try {
      await _storyService.followUser(followerFirebaseUid, targetUserFirebaseUid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User followed successfully!'), backgroundColor: AppColors.primaryBlue), 
      );
    } catch (e) {
      if (e.toString().contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already following this user.'), backgroundColor: AppColors.lightBlue), 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error following user: ${e.toString()}'), backgroundColor: AppColors.darkGrey), 
        );
      }
    }
  }

  void _onItemTapped(int index) async {
    setState(() {
      currentIndex = index;
    });

    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddStoryPage()),
      );
      _fetchStoriesFromBackend();
      setState(() {
        currentIndex = 0;
      });
    } 
    else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }

  }

  List<IconData> listOfIcons = [
    Icons.feed,
    Icons.add_circle,
    Icons.person,
  ];

  List<String> listOfLabels = [
    'Feed',
    'Add Story',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories Feed'),
        backgroundColor: AppColors.primaryBlue, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStoriesFromBackend,
            tooltip: 'Refresh Stories', 
          ),

        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)) 
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.darkGrey, size: 50), 
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.darkGrey, fontSize: 16), 
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchStoriesFromBackend,
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
              : _feedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, size: 60, color: AppColors.greyishBlue), 
                          const SizedBox(height: 10),
                          Text(
                            'No stories found. Be the first to share!',
                            style: TextStyle(fontSize: 18, color: AppColors.greyishBlue), 
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddStoryPage()),
                              ).then((_) => _fetchStoriesFromBackend());
                            },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Your First Story'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue, 
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth >= 900) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth >= 600) {
                          crossAxisCount = 2;
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _feedItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, index) {
                            final story = _feedItems[index];
                            return FeedItem(
                              imageUrl: story.photoUrl,
                              authorUsername: story.authorUsername,
                              authorAvatarUrl: story.authorAvatarUrl ?? 'assets/images/default_avatar.png',
                              description: story.description,
                              location: story.location,
                              createdAt: story.createdAt,
                              updatedAt: story.updatedAt,
                              postId: story.id,
                              authorFirebaseUid: story.authorFirebaseUid,
                              currentUserId: currentUserId,
                              onEdit: () => _editPost(story),
                              onDelete: () => _deletePost(story),
                              onFollow: () => _followUser(story.authorFirebaseUid),
                            );
                          },
                        );
                      },
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
              onTap: () {
                _onItemTapped(index);
              },
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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