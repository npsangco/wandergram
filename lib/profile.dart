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
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child("profile_pictures")
            .child("$fileName.jpg");
        await storageRef.putFile(_pickedProfileImage!);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("tbl_users")
            .doc(uid)
            .update({'profile_picture': downloadUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile picture updated!")),
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
  void _showPostDetail(BuildContext context, QueryDocumentSnapshot perpost) {
    final data = perpost.data() as Map<String, dynamic>;
    final String postDocId = perpost.id;
    final String userName = data['user_name'] ?? "User";
    final String content = data['content'] ?? "";
    final String imageUrl = data['image_url'] ?? "";
    final timestamp = data['timestamp'];
    final int likesCount = data['likes_count'] ?? 0;
    final int commentsCount = data['comments_count'] ?? 0;
    final String timestampStr = timestamp != null
        ? timestamp.toDate().toString().substring(0, 16)
        : "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kRiverCyan,
                          child:
                          Icon(Icons.person, color: kForestShadow),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepNavy),
                            ),
                            Text(
                              timestampStr,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: kSkyCream,
                            child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (content.isNotEmpty)
                      Text(content, style: const TextStyle(fontSize: 15, color: kDeepNavy)),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.thumb_up_alt_outlined, color: kSunsetOrange, size: 18),
                            label: Text('$likesCount Likes', style: const TextStyle(color: kDeepNavy, fontSize: 13)),
                          ),
                        ),
                        Container(height: 22, width: 1, color: Colors.grey[300]),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.comment_outlined, color: kCoralPink, size: 18),
                            label: Text('$commentsCount Comments', style: const TextStyle(color: kDeepNavy, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepNavy)),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("tbl_comments")
                          .where('post_id', isEqualTo: postDocId)
                          .snapshots(),
                      builder: (context, commentSnap) {
                        if (!commentSnap.hasData || commentSnap.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey))),
                          );
                        }
                        final comments = commentSnap.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            final String commentUserId = c['user_id'] ?? "";
                            return FutureBuilder<DocumentSnapshot>(
                              future: commentUserId.isNotEmpty
                                  ? FirebaseFirestore.instance.collection("tbl_users").doc(commentUserId).get()
                                  : Future.value(null),
                              builder: (context, userSnap) {
                                String commentorPic = "";
                                if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                                  commentorPic = (userSnap.data!.data() as Map<String, dynamic>)['profile_picture'] ?? "";
                                }
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: kAdventurePurple,
                                    backgroundImage: commentorPic.isNotEmpty ? NetworkImage(commentorPic) : null,
                                    child: commentorPic.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
                                  ),
                                  title: Text(c['user_name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(c['content'] ?? ""),
                                );
                              },
                            );
                          },
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        backgroundColor: kForestShadow,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: kCoralPink),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("tbl_users").doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kMountainBlue));

          final userdata = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String profilePicUrl = userdata['profile_picture'] ?? "";
          final List travelHistory = List.from(userdata['travel_history'] ?? []);
          final String userName = userdata['name'] ?? user?.displayName ?? "User";
          final String userEmail = user?.email ?? "";

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadProfilePicture(uid),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: kRiverCyan,
                            backgroundImage: _pickedProfileImage != null
                                ? FileImage(_pickedProfileImage!) as ImageProvider
                                : (profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null),
                            child: (_pickedProfileImage == null && profilePicUrl.isEmpty)
                                ? Icon(Icons.person, size: 46, color: kForestShadow)
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kSunsetOrange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploading
                                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Icon(Icons.edit, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDeepNavy)),
                          Text(userEmail, style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (travelHistory.isNotEmpty)
                Container(
                  color: Colors.white,
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: travelHistory.length,
                    itemBuilder: (context, index) {
                      final String trip = travelHistory[index].toString();
                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(radius: 26, backgroundColor: kAdventurePurple, child: Icon(Icons.flag, color: Colors.white, size: 22)),
                            SizedBox(height: 4),
                            Text(trip.length > 8 ? '${trip.substring(0, 8)}..' : trip, style: TextStyle(fontSize: 11, color: kDeepNavy)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Divider(height: 1, color: Colors.grey[300]),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('user_id', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text("Database error or missing index. Check logs.\n\n${snapshot.error}", textAlign: TextAlign.center),
                        ),
                      );
                    }
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kMountainBlue));

                    var posts = snapshot.data!.docs;
                    if (posts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text("No Posts Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: kDeepNavy)),
                            SizedBox(height: 6),
                            Text("Share your first travel photo!", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        var perpost = posts[index];
                        final data = perpost.data() as Map<String, dynamic>;
                        final String imageUrl = data['image_url'] ?? "";
                        final String content = data['content'] ?? "";

                        return GestureDetector(
                          onTap: () => _showPostDetail(context, perpost),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Container(
                            color: kForestShadow,
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: Text(
                                content.length > 40 ? '${content.substring(0, 40)}...' : content,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
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
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsfeedPage()));
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const PostPage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Newsfeed"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}