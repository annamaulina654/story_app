import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/models/follow_user_data.dart';
import 'package:story_app/services/follow_service.dart';

class FollowsPage extends StatefulWidget {
  final String userFirebaseUid;
  final String username;
  final int initialTabIndex; 

  const FollowsPage({
    super.key,
    required this.userFirebaseUid,
    required this.username,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends State<FollowsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService(baseUrl: 'http://localhost:3000/api');

  late Future<List<FollowUser>> _followersFuture;
  late Future<List<FollowUser>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadData();
  }
  
  void _loadData() {
    _followersFuture = _followService.getFollowers(widget.userFirebaseUid);
    _followingFuture = _followService.getFollowing(widget.userFirebaseUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followersFuture),
          _buildUserList(_followingFuture),
        ],
      ),
    );
  }

  Widget _buildUserList(Future<List<FollowUser>> future) {
    return FutureBuilder<List<FollowUser>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _UserListTile(
              user: users[index],
              followService: _followService,
            );
          },
        );
      },
    );
  }
}

class _UserListTile extends StatefulWidget {
  final FollowUser user;
  final FollowService followService;
  
  const _UserListTile({required this.user, required this.followService});

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  late bool _isFollowing;
  bool _isLoading = false;
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
  }
  
  Future<void> _toggleFollow() async {
    if (_currentUserUid == null) return;
    
    setState(() { _isLoading = true; });
    
    try {
      if (_isFollowing) {
        await widget.followService.unfollowUser(
          followerUid: _currentUserUid!,
          followedUid: widget.user.firebaseUid,
        );
      } else {
        await widget.followService.followUser(
          followerUid: _currentUserUid!,
          followedUid: widget.user.firebaseUid,
        );
      }
      setState(() { _isFollowing = !_isFollowing; });
    } catch (e) {
      // Handle error jika perlu
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = widget.user.firebaseUid == _currentUserUid;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
            ? NetworkImage(widget.user.profileImageUrl!)
            : const AssetImage('assets/images/user-profile.png') as ImageProvider,
      ),
      title: Text(widget.user.username),
      subtitle: widget.user.fullName != null ? Text(widget.user.fullName!) : null,
      trailing: isCurrentUser
          ? null 
          : SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                    : Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
    );
  }
}