import 'package:flutter/material.dart';
import 'package:story_app/models/feed_item_data.dart'; 

class StoryCard extends StatelessWidget {
  final FeedItemData story; 
  const StoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFB2EBF2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: story.photoUrl.isNotEmpty 
                  ? Image.network(
                      story.photoUrl, 
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image, size: 60, color: Colors.teal)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.authorUsername,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  story.description, 
                  style: const TextStyle(fontSize: 14, color: Color(0xFF00796B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF004D40)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        story.location != null && story.location!.isNotEmpty
                            ? story.location!
                            : 'Location not available',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF004D40)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF004D40)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        story.createdAt.toLocal().toString().split(' ')[0], 
                        style: const TextStyle(fontSize: 12, color: Color(0xFF004D40)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}