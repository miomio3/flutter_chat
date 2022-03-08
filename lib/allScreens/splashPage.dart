import 'package:flutter/material.dart';
import 'package:ichat_app/allProvider/authProvider.dart';
import 'package:ichat_app/allScreens/homePage.dart';
import 'package:ichat_app/allScreens/loginPage.dart';
import 'package:provider/provider.dart';

import '../allConstants/color_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  void checkSignedIn()async{
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();

    if(isLoggedIn){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage()));
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 5), (){
      checkSignedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
                'images/splash.png',
              height: 300,
                width: 300,
            ),
            SizedBox(height: 20,),
            Text(
              "World's Largest Private Chat App",
              style: TextStyle(color: ColorConstants.themeColor),
            ),
            SizedBox(height: 20,),
            Container(
              height: 20,
                width: 20,
              child: CircularProgressIndicator(color: ColorConstants.themeColor),
            )
          ],
        ),
      ),
    );
  }
}
