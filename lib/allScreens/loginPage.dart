import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/allProvider/authProvider.dart';
import 'package:ichat_app/allScreens/homePage.dart';
import 'package:ichat_app/allWidgets/loading_view.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {

    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch(authProvider.status){
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in failed...");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled...");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign in succeeded!");
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.all(20),
            child: Image.asset("images/back.png"),
          ),
          SizedBox(height: 20),
          Padding(
              padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: ()async{
                bool isSuccess = await authProvider.handleSignIn();
                if(isSuccess){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                }
              },
              child: Image.asset("images/google_login.jpg"),
            ),
          ),
          Stack(
            children: [
              Positioned(
                child: authProvider.status == Status.authenticating ? LoadingView() : SizedBox.shrink(),
              ),
            ],
          )
        ],
      ),
    );
  }
}
