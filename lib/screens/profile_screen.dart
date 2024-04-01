import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';

import '../resources/auth_method.dart';
import '../resources/firestore_methods.dart';
import '../widgets/follow_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Uint8List? _image;
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isLoading = false;

  bool isFollowing = false;
  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      // get post length
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      postLen = postSnap.docs.length;

      userData = userSnap.data()!;
      followers = userSnap.data()!['followers'].length;
      following = userSnap.data()!['following'].length;
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      setState(() {});
    } catch (e) {
      showSnackbar(e.toString(), context);
    }
    setState(() {
      isLoading = false;
    });
  }

  // void selectImage() async {
  //   Uint8List im = await pickImage(ImageSource.gallery);
  //   setState(() {
  //     _image = im;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(userData['username']),
              centerTitle: false,
            ),
            body: ListView(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                       
                      
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            backgroundImage: NetworkImage(userData['photoUrl']),
                            radius: 40,
                          ),
                        ),
                     
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  buildStateColumn(postLen, "post"),
                                  buildStateColumn(followers, "followers"),
                                  buildStateColumn(following, "following"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  FirebaseAuth.instance.currentUser!.uid ==
                                          widget.uid
                                      ? Followbutton(
                                          text: 'Logout',
                                          backgroundColor:
                                              mobileBackgroundColor,
                                          borderColor: Colors.grey,
                                          textColor: primaryColor,
                                          function: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Logout"),
                                                content: const Text(
                                                    "Are You sure you want to log out"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("No"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await AuthMethods()
                                                          .signOut();
                                                      Navigator.of(context)
                                                          .push(
                                                              MaterialPageRoute(
                                                        builder: (context) =>
                                                            const LoginScreen(),
                                                      ));
                                                    },
                                                    child: const Text("Yes"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })
                                      : isFollowing
                                          ? Followbutton(
                                              text: 'Unfollow',
                                              backgroundColor: Colors.white,
                                              borderColor: Colors.grey,
                                              textColor: Colors.black,
                                              function: () async {
                                                await FirestoreMethods()
                                                    .followUser(
                                                  FirebaseAuth.instance
                                                      .currentUser!.uid,
                                                  userData['uid'],
                                                );
                                                setState(() {
                                                  isFollowing = false;
                                                  followers--;
                                                });
                                              },
                                            )
                                          : Followbutton(
                                              text: 'follow',
                                              backgroundColor: Colors.blue,
                                              borderColor: Colors.blue,
                                              textColor: Colors.white,
                                              function: () async {
                                                await FirestoreMethods()
                                                    .followUser(
                                                  FirebaseAuth.instance
                                                      .currentUser!.uid,
                                                  userData['uid'],
                                                );
                                                setState(() {
                                                  isFollowing = true;
                                                  followers++;
                                                });
                                              },
                                            ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        userData['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        userData['bio'],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white54),
                FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('posts')
                      .where('uid', isEqualTo: widget.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: (snapshot.data! as dynamic).docs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 1.5,
                              childAspectRatio: 1),
                      itemBuilder: ((context, index) {
                        DocumentSnapshot snap =
                            (snapshot.data! as dynamic).docs[index];

                        return Container(
                          child: Image(
                            image: NetworkImage(snap['postUrl']),
                            fit: BoxFit.cover,
                          ),
                        );
                      }),
                    );
                  },
                )
              ],
            ),
          );
  }

  Column buildStateColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w400, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
