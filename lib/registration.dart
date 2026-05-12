import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullnameController = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSkyCream,
      body: Center(
        child: Container(
          margin: EdgeInsets.all(25),
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Image.asset(
                  'assets/wandergram_logo.png',
                  height: 300,
                ),
                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kDeepNavy,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Join the travel community!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: fullnameController,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? "Required" : null,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: TextStyle(color: kMountainBlue, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.person, color: kMountainBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kMountainBlue, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kSunsetOrange, width: 3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? "Required" : null,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: kMountainBlue, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.email, color: kMountainBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kMountainBlue, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kSunsetOrange, width: 3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? "Required" : null,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: kMountainBlue, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.lock, color: kMountainBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kMountainBlue, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kSunsetOrange, width: 3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: kMountainBlue,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        var nsfullname = fullnameController.text;
                        var nsemail = emailController.text;
                        var nspass = passwordController.text;
                        try {
                          var usercredential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                              email: nsemail, password: nspass);
                          await usercredential.user!.updateDisplayName(nsfullname);
                          await FirebaseFirestore.instance
                              .collection("tbl_users")
                              .doc(usercredential.user!.uid)
                              .set({
                            'user_id'        : usercredential.user!.uid,
                            'name'           : nsfullname,
                            'profile_picture': '',
                            'travel_history' : [],
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Registration successful!")),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message.toString())),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMountainBlue,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text("SIGN UP"),
                  ),
                ),
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kCoralPink,
                    side: BorderSide(color: kCoralPink, width: 2),
                    padding: EdgeInsets.all(14),
                    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("Already have an account? Login"),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}