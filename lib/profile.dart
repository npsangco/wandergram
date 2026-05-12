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
        title: Text(
          "My Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: kCoralPink),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
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
            return Center(
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
                EdgeInsets.symmetric(horizontal: 16, vertical: 16),

                child: Row(
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
                                ? Icon(Icons.person,
                                size: 46, color: kForestShadow)
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
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: _isUploading
                                  ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                                  : Icon(Icons.edit,
                                  color: Colors.white, size: 14),
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
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kDeepNavy,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    itemCount: travelHistory.length,
                    itemBuilder: (context, index) {
                      final String trip =
                      travelHistory[index].toString();
                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: kAdventurePurple,
                              child: Icon(Icons.flag,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.length > 8
                                  ? '${trip.substring(0, 8)}..'
                                  : trip,
                              style: TextStyle(
                                  fontSize: 11, color: kDeepNavy),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Divider(height: 1, color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('user_id', isEqualTo: postUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox();
                    }

                    var posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined,
                                size: 64, color: Colors.grey[400]),
                            SizedBox(height: 12),
                            Text(
                              "No Posts",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: kDeepNavy),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Share your first travel photo!",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        var perpost = posts[index];

                        final String content = perpost['content'] ?? "";
                        final String imageUrl = perpost['image_url'] ?? "";
                        final timestamp = perpost['timestamp'];
                        final int likesCount = perpost['likes_count'] ?? 0;
                        final int commentsCount = perpost['comments_count'] ?? 0;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
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
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              if (content.isNotEmpty)
                                Text(
                                  content,
                                  style: TextStyle(
                                      fontSize: 15, color: kDeepNavy),
                                ),
                              if (imageUrl.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 10),
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
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                color: kMountainBlue),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                            height: 80,
                                            color: kSkyCream,
                                            child: Center(
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
                                  child: Center(
                                    child: Text("No content",
                                        style:
                                        TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up_alt_outlined,
                                      color: kSunsetOrange, size: 18),
                                  SizedBox(width: 4),
                                  Text('$likesCount',
                                      style: TextStyle(
                                          color: Colors.grey)),
                                  SizedBox(width: 16),
                                  Icon(Icons.comment_outlined,
                                      color: kCoralPink, size: 18),
                                  SizedBox(width: 4),
                                  Text('$commentsCount',
                                      style: TextStyle(
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
              MaterialPageRoute(builder: (context) => NewsfeedPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostPage()),
            );
          }
        },
        items: [
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