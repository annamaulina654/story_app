import 'package:flutter/material.dart';
import 'package:story_app/constants/app_colors.dart';

class FeedItem extends StatelessWidget {
  final String imageUrl;
  final String authorUsername;
  final String authorAvatarUrl;
  final String description;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final int postId;
  final String authorFirebaseUid;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onFollow;

  const FeedItem({
    super.key,
    required this.imageUrl,
    required this.authorUsername,
    required this.authorAvatarUrl,
    this.description = '',
    this.location,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    required this.postId,
    required this.authorFirebaseUid,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.onFollow,
  });

  String _formatDisplayTime(DateTime createdTime, DateTime? updatedTime) {
    if (updatedTime != null && updatedTime.isAfter(createdTime.add(const Duration(seconds: 5)))) {
      return 'Diperbarui ${_formatTimestamp(updatedTime)}';
    } else {
      return 'Dibuat ${_formatTimestamp(createdTime)}';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2, 4)}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = (currentUserId != null && currentUserId == authorFirebaseUid);

    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: AppColors.primaryBlue.withOpacity(0.2),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color.fromARGB(255, 246, 246, 247),
                    backgroundImage: authorAvatarUrl.startsWith('http') || authorAvatarUrl.startsWith('https')
                        ? NetworkImage(authorAvatarUrl)
                        : AssetImage(authorAvatarUrl) as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading avatar: $exception');
                    },
                    child: (authorAvatarUrl.isEmpty ||
                            (!authorAvatarUrl.startsWith('http') &&
                                !authorAvatarUrl.startsWith('https') &&
                                !authorAvatarUrl.startsWith('assets')))
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorUsername,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.darkGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location != null && location!.isNotEmpty)
                          Text(
                            location!,
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: AppColors.greyishBlue, size: 24),
                    onSelected: (String result) {
                      if (isMyPost) {
                        if (result == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (result == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      } else {
                        if (result == 'follow' && onFollow != null) {
                          onFollow!();
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      if (isMyPost) {
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
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ];
                      } else {
                        return <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'follow',
                            child: Row(
                              children: [
                                Icon(Icons.person_add, size: 20),
                                SizedBox(width: 8),
                                Text('Ikuti'),
                              ],
                            ),
                          ),
                        ];
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                child: imageUrl.startsWith('http') || imageUrl.startsWith('https')
                    ? Image.network(
                        imageUrl,
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
                        imageUrl,
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
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, size: 20, color: AppColors.lightBlue),
                  const SizedBox(width: 6),
                  Text(
                    '$likesCount',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.comment, size: 20, color: AppColors.lightBlue),
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
                  const Spacer(),
                  Icon(Icons.share, size: 20, color: AppColors.lightBlue),
                ],
              ),
            ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
                child: Text(
                  description,
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
              padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
              child: Text(
                _formatDisplayTime(createdAt, updatedAt),
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
    );
  }
}