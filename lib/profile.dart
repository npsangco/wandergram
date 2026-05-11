import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'newsfeed.dart';
import 'post.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final travelHistoryController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  File? _pickedProfileImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";
    final String postUserId = user?.displayName ?? user?.email ?? "";

    return Scaffold(
      backgroundColor: Colors.white,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("tbl_users")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userdata =
                snapshot.data?.data() as Map<String, dynamic>? ?? {};
            return Text(
              userdata['name'] ?? user?.displayName ?? "Profile",
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false);
              }
            },
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tbl_users")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile"));
          }
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final userdata = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String profilePicUrl = userdata['profile_picture'] ?? "";
          final List travelHistory = List.from(userdata['travel_history'] ?? []);

          return Column(
            children: [
              // ── Profile top section ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => (context, uid),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.teal[100],
                                backgroundImage: _pickedProfileImage != null
                                    ? FileImage(_pickedProfileImage!) as ImageProvider
                                    : (profilePicUrl.isNotEmpty
                                        ? NetworkImage(profilePicUrl)
                                        : null),
                                child: (_pickedProfileImage == null && profilePicUrl.isEmpty)
                                    ? Icon(Icons.person, size: 46, color: Colors.teal[700])
                                    : null,
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal[700],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("tbl_posts")
                                .where('user_id', isEqualTo: postUserId)
                                .snapshots(),
                            builder: (context, postSnap) {
                              final postCount = postSnap.data?.docs.length ?? 0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statColumn(postCount.toString(), "Posts"),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userdata['name'] ?? "",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? "",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Travel history ──────────────────────────────────────────
              if (travelHistory.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: travelHistory.length,
                    itemBuilder: (context, index) {
                      final trip = travelHistory[index].toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                                ),
                              ),
                              child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: Text(
                                trip,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const Divider(height: 1),

              // ── Posts grid ──────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('user_id', isEqualTo: postUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading posts"));
                    }
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final posts = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "No Posts Yet",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Share your first travel photo!",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    posts.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      final tA = dataA['timestamp'] as Timestamp?;
                      final tB = dataB['timestamp'] as Timestamp?;
                      if (tA == null) return 1;
                      if (tB == null) return -1;
                      return tB.compareTo(tA);
                    });

                    return GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final data = posts[index].data() as Map<String, dynamic>;
                        final String imageUrl = data['image_url'] ?? '';
                        final String content = data['content'] ?? '';

                        return GestureDetector(
                          onTap: () => _showPostDetail(context, data),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.grey[100],
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => _noImageTile(content),
                                )
                              : _noImageTile(content),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.teal[700],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
                context, MaterialPageRoute(builder: (_) => const NewsfeedPage()), (route) => false);
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PostPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Newsfeed"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded, size: 35), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }

  Widget _noImageTile(String content) {
    return Container(
      color: Colors.teal[50],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.teal[700]),
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  void _showPostDetail(BuildContext context, Map<String, dynamic> data) {
    final String imageUrl = data['image_url'] ?? '';
    final String content = data['content'] ?? '';
    final int likesCount = data['likes_count'] ?? 0;
    final int commentsCount = data['comments_count'] ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            if (imageUrl.isNotEmpty) const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.teal),
                const SizedBox(width: 4),
                Text('$likesCount', style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined, size: 18, color: Colors.teal),
                const SizedBox(width: 4),
                Text('$commentsCount', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
