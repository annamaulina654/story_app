import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:story_app/constants/app_colors.dart';
import 'package:story_app/models/follow_user_data.dart';
import 'package:story_app/screens/profil_page.dart';
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
  final FollowService _followService = FollowService(baseUrl: 'https://story-app-api-eta.vercel.app/api');

  late Future<List<FollowUser>> _followersFuture;
  late Future<List<FollowUser>> _followingFuture;
  bool _hasMadeChanges = false; 

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

  void _onFollowStateChanged() {
    if (!_hasMadeChanges) {
      setState(() {
        _hasMadeChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_hasMadeChanges); 
      },
      child: Scaffold(
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
      )
    );
  }

  Widget _buildUserList(Future<List<FollowUser>> future) {
    return FutureBuilder<List<FollowUser>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
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
              onFollowChanged: _onFollowStateChanged, 
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
  final VoidCallback onFollowChanged; 

  const _UserListTile({
    required this.user, 
    required this.followService,
    required this.onFollowChanged,
  });

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
      if (mounted) {
        setState(() { _isFollowing = !_isFollowing; });
        widget.onFollowChanged();
      }
    } catch (e) {
      // Handle error jika perlu
      print("Error toggling follow: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = widget.user.firebaseUid == _currentUserUid;

    final followButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), 
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    final followingButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 0,
      side: BorderSide(color: Colors.grey.shade400), 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    return InkWell(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userFirebaseUid: widget.user.firebaseUid),
          ),
        );

        if (shouldRefresh == true && mounted) {
          widget.onFollowChanged(); 
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.user.profileImageUrl!)
                  : const AssetImage('assets/images/user-profile.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.user.fullName != null && widget.user.fullName!.isNotEmpty)
                    Text(widget.user.fullName!),
                ],
              ),
            ),
            if (!isCurrentUser)
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  style: _isFollowing ? followingButtonStyle : followButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : Text(_isFollowing ? 'Following' : 'Follow'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}