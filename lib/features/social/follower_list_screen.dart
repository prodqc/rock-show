import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_spacing.dart';

class FollowerListScreen extends ConsumerStatefulWidget {
  final String uid;
  final bool showFollowers; // true = followers, false = following

  const FollowerListScreen({
    required this.uid,
    this.showFollowers = true,
    super.key,
  });

  @override
  ConsumerState<FollowerListScreen> createState() => _FollowerListScreenState();
}

class _FollowerListScreenState extends ConsumerState<FollowerListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = FirebaseFirestore.instance;
    final sub = widget.showFollowers ? 'followers' : 'following';
    final snap = await db
        .collection('users')
        .doc(widget.uid)
        .collection(sub)
        .limit(50)
        .get();

    final List<Map<String, dynamic>> results = [];
    for (final doc in snap.docs) {
      final userDoc = await db.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        results.add({'uid': doc.id, ...userDoc.data()!});
      }
    }
    if (mounted) setState(() { _users = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showFollowers ? 'Followers' : 'Following';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('No $title yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final u = _users[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (u['avatarUrl'] ?? '').isNotEmpty
                            ? NetworkImage(u['avatarUrl'])
                            : null,
                        child: (u['avatarUrl'] ?? '').isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(u['displayName'] ?? ''),
                      subtitle: Text('@${u['username'] ?? ''}'),
                      onTap: () => context.push('/profile/${u['uid']}'),
                    );
                  },
                ),
    );
  }
}