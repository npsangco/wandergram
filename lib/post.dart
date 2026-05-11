import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'newsfeed.dart';

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

  // ── Pick image from gallery (PDF Step 4 method) ───────────────────────────
  Future<void> _pickImage() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── User header ──────────────────────────────────
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                FirebaseAuth.instance.currentUser
                                    ?.displayName ??
                                    "User",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Content field ────────────────────────────────
                          TextFormField(
                            controller: contentController,
                            maxLines: null,
                            style: const TextStyle(fontSize: 16),
                            validator: (value) =>
                            (value == null || value.isEmpty)
                                ? "Required"
                                : null,
                            decoration: const InputDecoration(
                              hintText: "What's on your mind?",
                              border: InputBorder.none,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Photo / Video picker row (sangco_3rdact Row style) ─
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              // Photo button
                              InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo,
                                          color: Colors.green),
                                      SizedBox(width: 5),
                                      Text("Photo"),
                                    ],
                                  ),
                                ),
                              ),
                              // Video (placeholder, no action)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.videocam,
                                        color: Colors.red),
                                    SizedBox(width: 5),
                                    Text("Video"),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Image preview ────────────────────────────────
                          if (selectedImage != null)
                            Stack(
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
                                // Remove image button
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                            () => selectedImage = null),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
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

          // ── Post button (PDF Step 4 upload method) ────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
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
                    final content = contentController.text;
                    String? uploadedImageUrl;

                    // ── Upload image to Firebase Storage ──────────
                    if (selectedImage != null) {
                      String fileName = DateTime.now()
                          .millisecondsSinceEpoch
                          .toString();
                      Reference storageRef = FirebaseStorage
                          .instance
                          .ref()
                          .child("post_images")
                          .child("$fileName.jpg");
                      await storageRef.putFile(selectedImage!);
                      uploadedImageUrl =
                      await storageRef.getDownloadURL();
                    }

                    final user =
                        FirebaseAuth.instance.currentUser;

                    // ── Save to tbl_posts with schema field names ─
                    final postRef = FirebaseFirestore.instance
                        .collection("tbl_posts")
                        .doc();

                    await postRef.set({
                      'post_id': postRef.id,
                      'user_id': user?.displayName ??
                          user?.email ??
                          "",
                      'content': content,
                      'image_url': uploadedImageUrl ?? '',
                      'timestamp': Timestamp.now(),
                      'likes_count': 0,
                      'comments_count': 0,
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Post submitted!')),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewsfeedPage()),
                            (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$e")),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isUploading = false);
                    }
                  }
                },
                child: _isUploading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  "Post",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}