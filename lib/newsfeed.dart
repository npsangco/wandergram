import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'post.dart';
import 'profile.dart';
import 'login.dart';
import 'comment.dart';

class NewsfeedPage extends StatelessWidget {
  const NewsfeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kForestShadow,
        automaticallyImplyLeading: false,
        title: const Text(
          "Wandergram",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: kRiverCyan,
                  child: Icon(Icons.person, color: kForestShadow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PostPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      "What's on your mind?",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("tbl_posts")           // tbl_posts — from schema
                  .orderBy("timestamp", descending: true) // timestamp — schema
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: kMountainBlue),
                  );
                }

                var posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "No Posts Yet",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: kDeepNavy),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Be the first to share a travel experience!",
                          style:
                          TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var perpost = posts[index];

                    final String postDocId = perpost.id;
                    final String userId = perpost['user_id'] ?? "";
                    final String userName = perpost['user_name'] ?? "";
                    final String content = perpost['content'] ?? "";
                    final String imageUrl = perpost['image_url'] ?? "";
                    final timestamp = perpost['timestamp'];
                    final int likesCount = perpost['likes_count'] ?? 0;
                    final int commentsCount = perpost['comments_count'] ?? 0;

                    final String timestampStr = timestamp != null
                        ? timestamp.toDate().toString().substring(0, 16)
                        : "Posting...";
                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: 10, left: 12, right: 12),
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: kRiverCyan,
                                  child:
                                  Icon(Icons.person, color: kForestShadow),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: kDeepNavy,
                                        ),
                                      ),
                                      Text(
                                        timestampStr,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (content.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                              child: Text(
                                content,
                                style: const TextStyle(
                                    fontSize: 15, color: kDeepNavy),
                              ),
                            ),
                          if (imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 220,
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: kMountainBlue),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) =>
                                  const SizedBox(),
                                ),
                              ),
                            ),
                          const Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                    },
                                    icon: const Icon(
                                        Icons.thumb_up_alt_outlined,
                                        color: kSunsetOrange,
                                        size: 18),
                                    label: Text(
                                      '$likesCount Likes',
                                      style: const TextStyle(
                                          color: kDeepNavy, fontSize: 13),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kSunsetOrange,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 22,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CommentPage(
                                            postId          : postDocId,
                                            postUserId      : userId,
                                            postContent     : content,
                                            postImageUrl    : imageUrl,
                                            postTimestamp   : timestampStr,
                                            postLikesCount  : likesCount,
                                            postCommentsCount: commentsCount,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.comment_outlined,
                                        color: kCoralPink, size: 18),
                                    label: Text(
                                      '$commentsCount Comments',
                                      style: const TextStyle(
                                          color: kDeepNavy, fontSize: 13),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kCoralPink,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: kSunsetOrange,
        unselectedItemColor: Colors.grey,
        backgroundColor: kForestShadow,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
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