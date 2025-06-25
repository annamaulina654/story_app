import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/main.dart';
import 'package:story_app/models/feed_item_data.dart';
import 'package:story_app/screens/add_story_page.dart';
import 'package:story_app/services/story_service.dart';
import 'package:story_app/utils/dialog_utils.dart';
import 'package:story_app/widgets/feed_item.dart';

class UserStoryFeedPage extends StatefulWidget {
  final List<FeedItemData> stories;
  final int initialIndex;

  const UserStoryFeedPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<UserStoryFeedPage> createState() => _UserStoryFeedPageState();
}

class _UserStoryFeedPageState extends State<UserStoryFeedPage> {
  late final ScrollController _scrollController;
  final double itemHeight = 450 + 16;
  late List<FeedItemData> _stories; 
  late final StoryService _storyService;

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories); 
    _storyService = StoryService("https://story-app-api-eta.vercel.app/api", supabase);
    _scrollController = ScrollController();

    Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        final scrollPosition = widget.initialIndex * itemHeight;
        _scrollController.jumpTo(scrollPosition);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _editPost(FeedItemData item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStoryPage(initialStoryData: item),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true); 
      }
    });
  }

  void _deletePost(FeedItemData item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool confirmDelete = await DialogUtils.showConfirmDeleteDialog(context);
    if (!confirmDelete) return;

    try {
      await _storyService.deleteStory(
        item.id.toString(),
        currentUser.uid,
        mediaUrl: item.photoUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story deleted successfully!'), backgroundColor: AppColors.greenSuccess),
      );
      setState(() {
        _stories.removeWhere((story) => story.id == item.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting story: $e'), backgroundColor: AppColors.darkGrey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stories"),
        ),
        body: const Center(
          child: Text("No stories remaining."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${_stories.first.authorUsername}'s Stories"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _stories.length, 
        itemBuilder: (context, index) {
          final story = _stories[index]; 
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: SizedBox(
              height: 450,
              child: FeedItem(
                imageUrl: story.photoUrl,
                authorUsername: story.authorUsername,
                authorAvatarUrl: story.authorAvatarUrl ?? '',
                description: story.description,
                location: story.location,
                createdAt: story.createdAt,
                updatedAt: story.updatedAt,
                postId: story.id,
                authorFirebaseUid: story.authorFirebaseUid,
                currentUserId: FirebaseAuth.instance.currentUser?.uid, 
                onEdit: () => _editPost(story),
                onDelete: () => _deletePost(story),
              ),
            ),
          );
        },
      ),
    );
  }
}