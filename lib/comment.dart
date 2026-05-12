import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class CommentPage extends StatefulWidget {
  final String postId;
  final String postUserId;
  final String postUserName;
  final String postContent;
  final String postImageUrl;
  final String postTimestamp;
  final int postLikesCount;
  final int postCommentsCount;

  const CommentPage({
    super.key,
    required this.postId,
    required this.postUserId,
    required this.postUserName,
    required this.postContent,
    required this.postImageUrl,
    required this.postTimestamp,
    required this.postLikesCount,
    required this.postCommentsCount,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final commentController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kForestShadow,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Comments",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(12),
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: kRiverCyan, child: Icon(Icons.person, color: kForestShadow)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.postUserName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepNavy)),
                                Text(widget.postTimestamp,
                                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.postContent.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Text(widget.postContent,
                            style: TextStyle(fontSize: 15, color: kDeepNavy)),
                      ],
                      if (widget.postImageUrl.isNotEmpty) ...[
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(widget.postImageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      SizedBox(height: 10),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection("tbl_posts").doc(widget.postId).snapshots(),
                        builder: (context, snapshot) {
                          int currentLikes = widget.postLikesCount;
                          int currentComments = widget.postCommentsCount;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            currentLikes = data['likes_count'] ?? 0;
                            currentComments = data['comments_count'] ?? 0;
                          }

                          return Row(
                            children: [
                              Icon(Icons.thumb_up_alt_outlined, color: kSunsetOrange, size: 16),
                              SizedBox(width: 4),
                              Text('$currentLikes Likes',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                              SizedBox(width: 14),
                              Icon(Icons.comment_outlined, color: kCoralPink, size: 16),
                              SizedBox(width: 4),
                              Text('$currentComments Comments',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepNavy)),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance.collection("tbl_comments").where('post_id', isEqualTo: widget.postId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No comments yet.", style: TextStyle(color: Colors.grey))));
                    }
                    var comments = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var c = comments[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: kAdventurePurple, child: Icon(Icons.person, color: Colors.white, size: 18)),
                          title: Text(c['user_name'] ?? "User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(c['content'] ?? ""),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Form(
              key: formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: kMountainBlue),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final user = FirebaseAuth.instance.currentUser;
                        final text = commentController.text;
                        commentController.clear();

                        try {
                          DocumentReference commentRef = FirebaseFirestore.instance.collection("tbl_comments").doc();
                          await FirebaseFirestore.instance.collection("tbl_comments").add({
                            'comment_id': commentRef.id,
                            'post_id': widget.postId,
                            'user_id': user?.uid ?? "User",
                            'user_name': user?.displayName ?? user?.email ?? "User",
                            'content': text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          await FirebaseFirestore.instance.collection("tbl_posts").doc(widget.postId).update({
                            'comments_count': FieldValue.increment(1),
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}