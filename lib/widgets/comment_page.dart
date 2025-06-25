import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/models/user_data.dart' as app_user;
import 'package:story_app/screens/profil_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentPage extends StatefulWidget {
  final int postId;

  const CommentPage({super.key, required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || _currentUserId == null) return;

    final commentsCollection = FirebaseFirestore.instance.collection('comments');
    final storyMetaRef = FirebaseFirestore.instance.collection('stories_meta').doc(widget.postId.toString());

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(commentsCollection.doc(), {
          'story_id': widget.postId,
          'user_id': _currentUserId,
          'comment_text': commentText,
          'timestamp': FieldValue.serverTimestamp(),
        });
        final metaSnapshot = await transaction.get(storyMetaRef);
        if (metaSnapshot.exists) {
            transaction.update(storyMetaRef, {'comments_count': FieldValue.increment(1)});
        } else {
            transaction.set(storyMetaRef, {'likes_count': 0, 'comments_count': 1});
        }
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('story_id', isEqualTo: widget.postId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Be the first to comment!'));
                }
                final comments = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return _CommentTile(commentData: data);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration.collapsed(hintText: 'Write a comment...'),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final Map<String, dynamic> commentData;

  const _CommentTile({required this.commentData});

  @override
  State<_CommentTile> createState() => __CommentTileState();
}

class __CommentTileState extends State<_CommentTile> {
  late Future<app_user.UserProfile> _userFuture;

  @override
  void initState() {
    super.initState();
    final userId = widget.commentData['user_id'] as String;
    _userFuture = _fetchUserData(userId);
  }

  Future<app_user.UserProfile> _fetchUserData(String firebaseUid) async {
    final url = 'http://localhost:3000/api/users/$firebaseUid';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return app_user.UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.commentData['comment_text'] ?? '';
    final timestamp = (widget.commentData['timestamp'] as Timestamp?)?.toDate();

    return FutureBuilder<app_user.UserProfile>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey),
            title: Container(color: Colors.grey[200], height: 14, width: 80),
            subtitle: Text(text),
          );
        }

        if (userSnapshot.hasData) {
          final user = userSnapshot.data!;
          return ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  ProfilePage(userFirebaseUid: user.firebaseUid)
                ));
              },
              child: CircleAvatar(
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : const AssetImage('assets/images/user-profile.png') as ImageProvider,
              ),
            ),
            title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(text),
            trailing: Text(
              timestamp != null ? TimeAgo.format(timestamp) : '',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          );
        }

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text("Unknown user", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(text),
        );
      },
    );
  }
}

class TimeAgo {
  static String format(DateTime date) {
    final duration = DateTime.now().difference(date);

    if (duration.inSeconds < 60) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }
}
