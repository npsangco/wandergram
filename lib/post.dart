import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'newsfeed.dart';
import 'profile.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final contentController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  File? selectedImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSkyCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kForestShadow,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Create Post",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: kRiverCyan,
                                child: Icon(Icons.person, color: kForestShadow),
                              ),
                              SizedBox(width: 10),
                              Text(
                                FirebaseAuth
                                        .instance
                                        .currentUser
                                        ?.displayName ??
                                    "User",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kDeepNavy,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: contentController,
                            maxLines: null,
                            style: TextStyle(fontSize: 16, color: kDeepNavy),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? "Required"
                                : null,
                            decoration: InputDecoration(
                              hintText: "Share your travel experience!",
                              border: InputBorder.none,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final pickedImage = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedImage != null) {
                                    setState(() {
                                      selectedImage = File(pickedImage.path);
                                    });
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.photo, color: kSunsetOrange),
                                    SizedBox(width: 5),
                                    Text(
                                      "Photo",
                                      style: TextStyle(color: kDeepNavy),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.videocam, color: kCoralPink),
                                  SizedBox(width: 5),
                                  Text(
                                    "Video",
                                    style: TextStyle(color: kDeepNavy),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          selectedImage == null
                              ? SizedBox()
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        selectedImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => selectedImage = null,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMountainBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => _isUploading = true);

                        try {
                          var content = contentController.text;
                          String? uploadedImageUrl;

                          if (selectedImage != null) {
                            String fileName = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            Reference storageRef = FirebaseStorage.instance
                                .ref()
                                .child("post_images")
                                .child("$fileName.jpg");
                            await storageRef.putFile(selectedImage!);
                            uploadedImageUrl = await storageRef
                                .getDownloadURL();
                          }
                          final user = FirebaseAuth.instance.currentUser;
                          await FirebaseFirestore.instance
                              .collection("tbl_posts")
                              .add({
                                'post_id': '',
                                'user_id': user?.uid ?? "",
                                'user_name': user?.displayName ?? "User",
                                'content': content,
                                'image_url': uploadedImageUrl ?? '',
                                'timestamp': FieldValue.serverTimestamp(),
                                'likes_count': 0,
                                'comments_count': 0,
                              });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Post submitted!")),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsfeedPage(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("$e")));
                        } finally {
                          if (mounted) setState(() => _isUploading = false);
                        }
                      },
                child: _isUploading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Post",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Newsfeed",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded),
            label: "Post",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
