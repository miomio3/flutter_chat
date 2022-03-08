import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ichat_app/allConstants/app_constants.dart';
import 'package:ichat_app/allProvider/authProvider.dart';
import 'package:ichat_app/allProvider/chatProvider.dart';
import 'package:ichat_app/allProvider/honeProvider.dart';
import 'package:ichat_app/allProvider/settingsProvider.dart';
import 'package:ichat_app/allScreens/splashPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


bool isWhite = false;

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();


  runApp(MyApp(prefs: prefs));
}



class MyApp extends StatelessWidget
{
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  MyApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
                googleSignIn: GoogleSignIn(),
                firebaseAuth: FirebaseAuth.instance,
                firebaseFirestore: this.firebaseFirestore,
                prefs: this.prefs
            )
        ),
        Provider<SettingsProvider>(
            create: (_) => SettingsProvider(
                prefs: this.prefs,
                firebaseStorage: this.firebaseStorage,
                firebaseFirestore: this.firebaseFirestore),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
              firebaseFirestore: this.firebaseFirestore
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
            firebaseFirestore: this.firebaseFirestore,
            firebaseStorage: this.firebaseStorage,
            prefs: this.prefs
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          primaryColor: Colors.black,
        ),
        home: SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

