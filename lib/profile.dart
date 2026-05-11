import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'newsfeed.dart';
import 'post.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _pickedProfileImage;
  bool _isUploading = false;

  Future<void> _pickAndUploadProfilePicture(String uid) async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _pickedProfileImage = File(pickedImage.path);
      });

      try {
        setState(() => _isUploading = true);

        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child("profile_pictures").child("$fileName.jpg");
        await storageRef.putFile(_pickedProfileImage!);
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection("tbl_users")
            .doc(uid)
            .update({'profile_picture': downloadUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
  Widget _statColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: kDeepNavy),
        ),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";
    final String postUserId = user?.displayName ?? user?.email ?? "";

    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        backgroundColor: kForestShadow,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "My Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: kCoralPink),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tbl_users")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: kMountainBlue));
          }

          final userdata = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String profilePicUrl = userdata['profile_picture'] ?? "";
          final List travelHistory = List.from(userdata['travel_history'] ?? []);
          final String userName  = user?.displayName ?? "";
          final String userEmail = user?.email ?? "";

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('user_id', isEqualTo: postUserId)
                      .snapshots(),
                  builder: (context, postSnap) {

                    final int postCount =
                        postSnap.data?.docs.length ?? 0;
                    int totalLikes = 0;
                    if (postSnap.hasData) {
                      for (var doc in postSnap.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalLikes += (data['likes_count'] as int? ?? 0);
                      }
                    }

                    return Column(
                      children: [

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _pickAndUploadProfilePicture(uid),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: kRiverCyan,
                                    backgroundImage:
                                    _pickedProfileImage != null
                                        ? FileImage(_pickedProfileImage!)
                                    as ImageProvider
                                        : (profilePicUrl.isNotEmpty
                                        ? NetworkImage(profilePicUrl)
                                        : null),
                                    child: (_pickedProfileImage == null &&
                                        profilePicUrl.isEmpty)
                                        ? const Icon(Icons.person,
                                        size: 46, color: kForestShadow)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: kSunsetOrange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: _isUploading
                                          ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                          : const Icon(Icons.edit,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kDeepNavy,
                                    ),
                                  ),
                                  Text(
                                    userEmail,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),

                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.start,
                                    children: [
                                      _statColumn(
                                          postCount.toString(), "Posts"),
                                      const SizedBox(width: 30),
                                      _statColumn(
                                          totalLikes.toString(), "Likes"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              if (travelHistory.isNotEmpty)
                Container(
                  color: Colors.white,
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    itemCount: travelHistory.length,
                    itemBuilder: (context, index) {
                      final String trip =
                      travelHistory[index].toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: kAdventurePurple,
                              child: const Icon(Icons.flag,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.length > 8
                                  ? '${trip.substring(0, 8)}..'
                                  : trip,
                              style: const TextStyle(
                                  fontSize: 11, color: kDeepNavy),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const Divider(height: 1, color: Colors.grey),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('user_id', isEqualTo: postUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    var posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "No Posts",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: kDeepNavy),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Share your first travel photo!",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        var perpost = posts[index];

                        final String content = perpost['content'] ?? "";
                        final String imageUrl = perpost['image_url'] ?? "";
                        final timestamp = perpost['timestamp'];
                        final int likesCount = perpost['likes_count'] ?? 0;
                        final int commentsCount = perpost['comments_count'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                timestamp != null
                                    ? timestamp.toDate().toString().substring(0, 16)
                                    : "Posting...",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),

                              const SizedBox(height: 8),

                              if (content.isNotEmpty)
                                Text(
                                  content,
                                  style: const TextStyle(
                                      fontSize: 15, color: kDeepNavy),
                                ),

                              if (imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          height: 180,
                                          color: Colors.grey[100],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                color: kMountainBlue),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                            height: 80,
                                            color: kSkyCream,
                                            child: const Center(
                                              child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                    ),
                                  ),
                                )
                              else if (content.isEmpty)
                                Container(
                                  height: 80,
                                  color: kSkyCream,
                                  child: const Center(
                                    child: Text("No content",
                                        style:
                                        TextStyle(color: Colors.grey)),
                                  ),
                                ),

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined,
                                      color: kSunsetOrange, size: 18),
                                  const SizedBox(width: 4),
                                  Text('$likesCount',
                                      style: const TextStyle(
                                          color: Colors.grey)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.comment_outlined,
                                      color: kCoralPink, size: 18),
                                  const SizedBox(width: 4),
                                  Text('$commentsCount',
                                      style: const TextStyle(
                                          color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: kSunsetOrange,
        unselectedItemColor: Colors.grey,
        backgroundColor: kForestShadow,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsfeedPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: "Newsfeed"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded), label: "Post"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}