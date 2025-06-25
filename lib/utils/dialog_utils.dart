import 'package:flutter/material.dart';

class DialogUtils {
  static Future<bool> showConfirmDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom( foregroundColor: Colors.black),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; 
  }
}