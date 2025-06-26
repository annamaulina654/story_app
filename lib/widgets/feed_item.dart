import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:provider/provider.dart'; 
import 'package:story_app/constants/app_colors.dart'; 
import 'package:story_app/providers/follow_status_provider.dart';
import 'package:story_app/screens/profil_page.dart'; 
import 'comment_page.dart';

class FeedItem extends StatefulWidget {
  final String imageUrl;
  final String authorUsername;
  final String authorAvatarUrl;
  final String description;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final int postId;
  final String authorFirebaseUid;
  final String? currentUserId; 
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FeedItem({
    super.key,
    required this.imageUrl,
    required this.authorUsername,
    required this.authorAvatarUrl,
    this.description = '',
    this.location,
    required this.createdAt,
    this.updatedAt,
    required this.postId,
    required this.authorFirebaseUid,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  bool _hasLiked = false;
  String? _currentFirebaseUserUid;

  @override
  void initState() {
    super.initState();
    _currentFirebaseUserUid = FirebaseAuth.instance.currentUser?.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentFirebaseUserUid != null && _currentFirebaseUserUid != widget.authorFirebaseUid) {
        Provider.of<FollowStatusProvider>(context, listen: false).checkInitialFollowStatus(
          followerUid: _currentFirebaseUserUid!,
          followedUid: widget.authorFirebaseUid,
        );
      }
    });

    _checkInitialLikeStatus();
  }

  void _checkInitialLikeStatus() async {
    if (_currentFirebaseUserUid != null) {
      final likeDocRef = FirebaseFirestore.instance
          .collection('likes')
          .doc('${widget.postId}_$_currentFirebaseUserUid');
      final likeSnapshot = await likeDocRef.get();
      if (mounted) {
        setState(() {
          _hasLiked = likeSnapshot.exists;
        });
      }
    }
  }

  String _formatDisplayTime(DateTime createdTime, DateTime? updatedTime) {
    if (updatedTime != null && updatedTime.isAfter(createdTime.add(const Duration(seconds: 5)))) {
      return 'Updated ${_formatTimestamp(updatedTime)}';
    } else {
      return 'Created ${_formatTimestamp(createdTime)}';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2, 4)}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _toggleLike() async {
    if (_currentFirebaseUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must log in to like this story.')),
      );
      return;
    }

    setState(() {
      _hasLiked = !_hasLiked;
    });

    final String storyIdString = widget.postId.toString();
    final likeDocRef = FirebaseFirestore.instance.collection('likes').doc('${storyIdString}_$_currentFirebaseUserUid');
    final storyMetaRef = FirebaseFirestore.instance.collection('stories_meta').doc(storyIdString);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final likeSnapshot = await transaction.get(likeDocRef);
        final storyMetaSnapshot = await transaction.get(storyMetaRef);

        if (!storyMetaSnapshot.exists) {
          transaction.set(storyMetaRef, {'likes_count': 0, 'comments_count': 0});
        }

        if (likeSnapshot.exists) {
          transaction.delete(likeDocRef);
          transaction.update(storyMetaRef, {'likes_count': FieldValue.increment(-1)});
        } else {
          transaction.set(likeDocRef, {
            'story_id': widget.postId,
            'user_id': _currentFirebaseUserUid,
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(storyMetaRef, {'likes_count': FieldValue.increment(1)});
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasLiked = !_hasLiked;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like story: $error')),
      );
    }
  }

  void _toggleFollow() async {
    if (_currentFirebaseUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must log in to follow the user.')),
      );
      return;
    }
    if (_currentFirebaseUserUid == widget.authorFirebaseUid) {
      return;
    }

    final followStatusProvider = Provider.of<FollowStatusProvider>(context, listen: false);
    final currentStatus = followStatusProvider.getFollowStatus(widget.authorFirebaseUid);

    final success = await followStatusProvider.toggleFollow(
      followerUid: _currentFirebaseUserUid!,
      followedUid: widget.authorFirebaseUid,
      currentStatus: currentStatus,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change follow status.')),
      );
    }
  }

  void _addComment(BuildContext context) {
    if (_currentFirebaseUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must log in to comment.')),
      );
      return;
    }
    _showAddCommentDialog(context, widget.postId, _currentFirebaseUserUid!);
  }

  void _showAddCommentDialog(BuildContext context, int storyId, String currentFirebaseUid) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: 'Write your comment...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final commentText = commentController.text.trim();
                if (commentText.isNotEmpty) {
                  await _submitComment(storyId, currentFirebaseUid, commentText);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitComment(int storyId, String currentFirebaseUid, String commentText) async {
    final String storyIdString = storyId.toString();
    final commentsCollectionRef = FirebaseFirestore.instance.collection('comments');
    final storyMetaRef = FirebaseFirestore.instance.collection('stories_meta').doc(storyIdString);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final storyMetaSnapshot = await transaction.get(storyMetaRef);
        transaction.set(commentsCollectionRef.doc(), {
          'story_id': storyId,
          'user_id': currentFirebaseUid,
          'comment_text': commentText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (storyMetaSnapshot.exists && storyMetaSnapshot.data() != null) {
          transaction.update(storyMetaRef, {'comments_count': FieldValue.increment(1)});
        } else {
          transaction.set(storyMetaRef, {'likes_count': 0, 'comments_count': 1});
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyPost = (_currentFirebaseUserUid != null && _currentFirebaseUserUid == widget.authorFirebaseUid);
    final bool showFollowButton = (_currentFirebaseUserUid != null && _currentFirebaseUserUid != widget.authorFirebaseUid);
    final String storyIdString = widget.postId.toString();

    return Consumer<FollowStatusProvider>(
      builder: (context, followStatusProvider, child) {
        final isFollowing = followStatusProvider.getFollowStatus(widget.authorFirebaseUid);

        return Card(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: AppColors.primaryBlue.withOpacity(0.2),
          margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
                  child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                                userFirebaseUid: widget.authorFirebaseUid),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color.fromARGB(255, 246, 246, 247),
                        backgroundImage: widget.authorAvatarUrl
                                    .startsWith('http') ||
                                widget.authorAvatarUrl.startsWith('https')
                            ? NetworkImage(widget.authorAvatarUrl)
                            : AssetImage(widget.authorAvatarUrl)
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                      userFirebaseUid: widget.authorFirebaseUid),
                                ),
                              );
                            },
                            child: Text(
                              widget.authorUsername,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.location != null &&
                              widget.location!.isNotEmpty)
                            Text(
                              widget.location!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.greyishBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (showFollowButton)
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? AppColors.greyishBlue
                              : AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 30),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (isMyPost)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz,
                            color: AppColors.greyishBlue, size: 24),
                        onSelected: (String result) {
                          if (result == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (result == 'delete' &&
                              widget.onDelete != null) {
                            widget.onDelete!();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                  ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    child: widget.imageUrl.startsWith('http') || widget.imageUrl.startsWith('https')
                        ? Image.network(
                            widget.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: AppColors.greyishBlue, size: 50),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            widget.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: AppColors.greyishBlue, size: 50),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('stories_meta').doc(storyIdString).snapshots(),
                            builder: (context, snapshot) {
                              int likesCount = 0;
                              if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                                final data = snapshot.data!.data() as Map<String, dynamic>;
                                likesCount = (data['likes_count'] as num?)?.toInt() ?? 0;
                              }

                              return Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero, 
                                    constraints: const BoxConstraints(), 
                                    visualDensity: VisualDensity.compact, 
                                    icon: Icon(
                                      _hasLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 24, 
                                      color: _hasLiked ? AppColors.primaryBlue : AppColors.lightBlue,
                                    ),
                                    onPressed: _toggleLike,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$likesCount',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('stories_meta').doc(storyIdString).snapshots(),
                            builder: (context, snapshot) {
                              int commentsCount = 0;
                              if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                                final data = snapshot.data!.data() as Map<String, dynamic>;
                                commentsCount = (data['comments_count'] as num?)?.toInt() ?? 0;
                              }

                              return Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero, 
                                    constraints: const BoxConstraints(), 
                                    visualDensity: VisualDensity.compact, 
                                    icon: const Icon(Icons.comment, size: 24, color: AppColors.lightBlue), 
                                    // onPressed: () => _addComment(context),
                                    onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommentPage(postId: widget.postId),
                                      ),
                                    );
                                  },

                                  ),
                                  const SizedBox(width: 6), 
                                  Text(
                                    '$commentsCount',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                      if (widget.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only( bottom: 4.0, left: 10.0),
                          child: Text(
                            widget.description,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, left: 10.0), 
                        child: Text(
                          _formatDisplayTime(widget.createdAt, widget.updatedAt),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.greyishBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}