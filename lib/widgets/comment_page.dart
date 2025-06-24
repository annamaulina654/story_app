import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/constants/app_colors.dart';

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

    final storyId = widget.postId.toString();
    final commentsCollection = FirebaseFirestore.instance.collection('comments');
    final storyMetaRef = FirebaseFirestore.instance.collection('stories_meta').doc(storyId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // ✅ BACA dulu
        final metaSnapshot = await transaction.get(storyMetaRef);

        // ✅ Baru TULIS
        transaction.set(commentsCollection.doc(), {
          'story_id': widget.postId,
          'user_id': _currentUserId,
          'comment_text': commentText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ✅ Update atau buat meta dokumen
        if (metaSnapshot.exists) {
          transaction.update(storyMetaRef, {'comments_count': FieldValue.increment(1)});
        } else {
          transaction.set(storyMetaRef, {'likes_count': 0, 'comments_count': 1});
        }
      }

      );

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyId = widget.postId.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('story_id', isEqualTo: widget.postId.toString)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final text = data['comment_text'] ?? '';
                    final userId = data['user_id'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(text),
                      subtitle: Text(
                        timestamp != null
                            ? '${timestamp.toLocal()}'.split('.')[0]
                            : 'Just now',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0), // Jarak dari sisi layar
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
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
          ),

        ],
      ),
    );
  }
}
