import 'package:flutter/material.dart';
import 'package:story_app/services/follow_service.dart';

class FollowStatusProvider extends ChangeNotifier {
  final FollowService _followService;
  final Map<String, bool> _followStatuses = {};

  FollowStatusProvider(this._followService);

  bool getFollowStatus(String userFirebaseUid) {
    return _followStatuses[userFirebaseUid] ?? false;
  }

  void updateFollowStatus(String userFirebaseUid, bool status) {
    if (_followStatuses[userFirebaseUid] != status) { 
      _followStatuses[userFirebaseUid] = status;
      notifyListeners(); 
    }
  }

  Future<void> checkInitialFollowStatus({
    required String followerUid,
    required String followedUid,
  }) async {
    if (followerUid == followedUid) {
      updateFollowStatus(followedUid, false); 
      return;
    }

    if (_followStatuses.containsKey(followedUid)) {
      return;
    }

    try {
      final bool status = await _followService.isFollowing(
        followerUid: followerUid,
        followedUid: followedUid,
      );
      updateFollowStatus(followedUid, status);
    } catch (e) {
      updateFollowStatus(followedUid, false); 
    }
  }

  Future<bool> toggleFollow({
    required String followerUid,
    required String followedUid,
    required bool currentStatus, 
  }) async {
    if (followerUid == followedUid) {
      return false; 
    }

    bool success;
    try {
      if (!currentStatus) {
        success = await _followService.followUser(
          followerUid: followerUid,
          followedUid: followedUid,
        );
      } else { 
        success = await _followService.unfollowUser(
          followerUid: followerUid,
          followedUid: followedUid,
        );
      }

      if (success) {
        updateFollowStatus(followedUid, !currentStatus);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}