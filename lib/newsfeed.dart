import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'post.dart';
import 'profile.dart';
import 'login.dart';
import 'comment.dart';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});
  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  String _currentUserProfilePic = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfilePic();
  }

  Future<void> _loadCurrentUserProfilePic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection("tbl_users").doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _currentUserProfilePic = (doc.data() as Map<String, dynamic>)['profile_picture'] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? "";
    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kForestShadow,
        automaticallyImplyLeading: false,
        title: Text(
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kRiverCyan,
                  backgroundImage: _currentUserProfilePic.isNotEmpty
                      ? NetworkImage(_currentUserProfilePic)
                      : null,
                  child: _currentUserProfilePic.isEmpty
                      ? Icon(Icons.person, color: kForestShadow)
                      : null,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PostPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
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
                  .collection("tbl_posts")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: kMountainBlue),
                  );
                }
                var posts = snapshot.data!.docs;
                if (posts.isEmpty) {
                  return Center(
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
                  padding: EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var perpost = posts[index];
                    final data = perpost.data();

                    final String postDocId = perpost.id;
                    final String userId = data['user_id'] ?? "";
                    final String userName = data['user_name'] ?? userId;
                    final String content = data['content'] ?? "";
                    final String imageUrl = data['image_url'] ?? "";
                    final timestamp = data['timestamp'];
                    final int likesCount = data['likes_count'] ?? 0;
                    final int commentsCount = data['comments_count'] ?? 0;
                    final List likedBy = List.from(data['liked_by'] ?? []);
                    final bool alreadyLiked = likedBy.contains(currentUid);

                    final String timestampStr = timestamp != null
                        ? timestamp.toDate().toString().substring(0, 16)
                        : "Posting...";
                    return Container(
                      margin: EdgeInsets.only(
                          bottom: 10, left: 12, right: 12),
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
                          Padding(
                            padding:
                            EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: Row(
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection("tbl_users").doc(userId).get(),
                                  builder: (context, userSnap) {
                                    String picUrl = "";
                                    if (userSnap.hasData && userSnap.data!.exists) {
                                      picUrl = (userSnap.data!.data() as Map<String, dynamic>)['profile_picture'] ?? "";
                                    }
                                    return CircleAvatar(
                                      backgroundColor: kRiverCyan,
                                      backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
                                      child: picUrl.isEmpty ? Icon(Icons.person, color: kForestShadow) : null,
                                    );
                                  },
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: kDeepNavy,
                                        ),
                                      ),
                                      Text(
                                        timestampStr,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (content.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  14, 10, 14, 0),
                              child: Text(
                                content,
                                style: TextStyle(
                                    fontSize: 15, color: kDeepNavy),
                              ),
                            ),
                          if (imageUrl.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
                              child: Image.network(
                                imageUrl,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 220,
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: kMountainBlue),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => SizedBox(),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Divider(
                                height: 1,
                                color: Color(0xFFEEEEEE)),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      if (alreadyLiked) {
                                        await FirebaseFirestore.instance
                                            .collection("tbl_posts")
                                            .doc(postDocId)
                                            .update({
                                          'liked_by'   : FieldValue.arrayRemove([currentUid]),
                                          'likes_count': FieldValue.increment(-1),
                                        });
                                      } else {
                                        await FirebaseFirestore.instance
                                            .collection("tbl_posts")
                                            .doc(postDocId)
                                            .update({
                                          'liked_by'   : FieldValue.arrayUnion([currentUid]),
                                          'likes_count': FieldValue.increment(1),
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      alreadyLiked
                                          ? Icons.thumb_up_alt
                                          : Icons.thumb_up_alt_outlined,
                                      color: alreadyLiked
                                          ? kSunsetOrange
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '$likesCount Likes',
                                      style: TextStyle(
                                        color: alreadyLiked
                                            ? kSunsetOrange
                                            : kDeepNavy,
                                        fontSize: 13,
                                        fontWeight: alreadyLiked
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
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
                                            postUserName    : userName,
                                            postContent     : content,
                                            postImageUrl    : imageUrl,
                                            postTimestamp   : timestampStr,
                                            postLikesCount  : likesCount,
                                            postCommentsCount: commentsCount,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.comment_outlined,
                                        color: kCoralPink, size: 18),
                                    label: Text(
                                      '$commentsCount Comments',
                                      style: TextStyle(
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
              MaterialPageRoute(builder: (context) => PostPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
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