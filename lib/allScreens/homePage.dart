import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ichat_app/allConstants/color_constants.dart';
import 'package:ichat_app/allConstants/constants.dart';
import 'package:ichat_app/allModels/popupChoices.dart';
import 'package:ichat_app/allModels/userChat.dart';
import 'package:ichat_app/allProvider/authProvider.dart';
import 'package:ichat_app/allScreens/loginPage.dart';
import 'package:ichat_app/allScreens/settingsPage.dart';
import 'package:ichat_app/allWidgets/loading_view.dart';
import 'package:ichat_app/main.dart';
import 'package:ichat_app/utilities/utilities.dart';
import 'package:provider/provider.dart';
import 'package:ichat_app/allProvider/honeProvider.dart';
import 'package:ichat_app/allScreens/chatPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  final StreamController btnclearController = StreamController<bool>();
  final TextEditingController searchBarController = TextEditingController();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //Debouncer searchDebouncer = Debouncer(milliseconds: 300);

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: "Sign out", icon: Icons.exit_to_app),
    PopupChoices(title: "Settings", icon: Icons.settings)
  ];

  void handleSignOut(){
    authProvider.handleSignOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void onItemPressed(PopupChoices choice){
    if(choice.title == "Sign out"){
      handleSignOut();
    }
    else{
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
    }
  }

  buildPopupMenu(){
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: isWhite ? Colors.grey : Colors.white,),
      onSelected: onItemPressed,
        itemBuilder: (BuildContext context){
          return choices.map((PopupChoices choice){
            return PopupMenuItem<PopupChoices>(
              value: choice,
                child: Row(
                  children: [
                    Icon(
                      choice.icon,
                      color: ColorConstants.primaryColor,
                    ),
                    SizedBox(width: 10,),
                    Text(
                        choice.title,
                      style: TextStyle(color: ColorConstants.primaryColor),
                    ),
                  ],
                ),
            );
          }).toList();
        }
    );
  }

  void listScrollListener(){
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      _limit += _limitIncrement;
    }
  }

  Widget buildSearchBar(){
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: ColorConstants.greyColor,size: 20,),
          SizedBox(width: 5,),
          Expanded(
              child: TextFormField(
                textInputAction: TextInputAction.search,
                controller: searchBarController,
                onChanged: (value){
                  if(value.isNotEmpty){
                    btnclearController.add(true);
                    setState(() {
                      _textSearch = value;
                    });
                  }
                  else{
                    btnclearController.add(false);
                    setState(() {
                      _textSearch = "";
                    });
                  }
                },
                decoration: InputDecoration.collapsed(
                    hintText: "Search",
                  hintStyle: TextStyle(fontSize: 13, color: ColorConstants.greyColor),
                ),
                style: TextStyle(fontSize: 13),
              ),
          ),
          StreamBuilder(
              stream: btnclearController.stream,
              builder: (context, snapshot){
              return snapshot.data == true ?
                  GestureDetector(
                    onTap: (){
                      searchBarController.clear();
                      btnclearController.add(false);
                      setState(() {
                        _textSearch = "";
                      });
                    },
                    child: Icon(Icons.clear_rounded, color: ColorConstants.greyColor, size: 20,),
                  )
                  : SizedBox.shrink();
            }
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
    );
  }
  
  Widget buildItem(BuildContext context, DocumentSnapshot? doc){
    if(doc != null){
      UserChat userChat = UserChat.fromDoc(doc);
      if(userChat.id == currentUserId){
        return SizedBox.shrink();
      }else{
        return Container(
          child: TextButton(
            onPressed: (){
              if(Utilities.isKeyboardShowing()){
                Utilities.closeKeyboard(context);
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                  ChatPage(peerId: userChat.id, peerNickname: userChat.nickname, peerAvatar: userChat.photoUrl,))
              );
            },
            child: Row(
              children: [
                Material(
                  child: userChat.photoUrl.isNotEmpty ? 
                    Image.network(
                      userChat.photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null){
                          return child;
                        }else{
                          return Container(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              value: loadingProgress.expectedTotalBytes != null && loadingProgress.cumulativeBytesLoaded != null ?
                                loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (context, object, stackTrace){
                        return Icon(Icons.account_circle, size: 50, color: ColorConstants.greyColor,);
                      },
                    ) : Icon(Icons.account_circle, size: 50, color: ColorConstants.greyColor,),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                ),
                Flexible(
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            child: Text(
                              "${userChat.nickname}",
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                          ),
                          Container(
                            child: Text(
                              "${userChat.aboutMe}",
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                          )
                        ],
                      ),
                      margin: EdgeInsets.only(left: 20),
                    )
                )
              ],
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.greyColor2),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))
                )
              )
            ),
          ),
        );
      }
    }
    return Icon(Icons.account_circle, size: 50, color: ColorConstants.greyColor,);
  }

  Future<void> openDialog()async{
    switch(
    await showDialog(context: context, builder: (BuildContext context){
      return SimpleDialog(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.zero,
        children: [
          Container(
            color: ColorConstants.themeColor,
            padding: EdgeInsets.only(bottom: 10, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: Icon(Icons.exit_to_app, size: 30, color: Colors.white,),
                  margin: EdgeInsets.only(bottom: 10),
                ),
                Text("Exit app", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),),
                Text("Are you sure to exit?", style: TextStyle(color: Colors.white, fontSize: 14),)
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context, 0);
            },
            child: Row(
              children: [
                Container(
                  child: Icon(Icons.cancel, color: ColorConstants.primaryColor,),
                  margin: EdgeInsets.only(right: 10),
                ),
                Text("Cancel", style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.bold),)
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context, 1);
            },
            child: Row(
              children: [
                Container(
                  child: Icon(Icons.check, color: ColorConstants.primaryColor,),
                  margin: EdgeInsets.only(right: 10),
                ),
                Text("Yes", style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.bold),)
              ],
            ),
          )
        ],
      );
    })
    ){
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<bool> onBackPress(){
    openDialog();
    return Future.value(false);
  }

  @override
  void dispose() {
    super.dispose();
    btnclearController.close();
  }

  @override
  void initState() {
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);

    if(authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }
    else{
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false
      );
    }
    listScrollController.addListener(listScrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value){
              setState(() {
                isWhite = value;
                print(isWhite);
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
            inactiveTrackColor: Colors.grey,
          ),
          onPressed: (){},
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildSearchBar(),
                Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: homeProvider.getStreamFirestore(FirestoreConstants.pathUserCollection, _limit, _textSearch),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                        if(snapshot.hasData){
                          if((snapshot.data?.docs.length ?? 0) > 0){
                            return ListView.builder(
                              itemCount: snapshot.data?.docs.length,
                              itemBuilder: (context, index) => buildItem(context, snapshot.data!.docs[index]),
                            );
                          }else{
                            return Center(
                              child: Text(
                                  "No user found",
                                style: TextStyle(color: ColorConstants.greyColor, fontSize: 20),
                              ),
                            );
                          }
                        }else{
                          return Center(
                            child: Text(
                                "No user found",
                              style: TextStyle(color: ColorConstants.greyColor, fontSize: 20),
                            ),
                          );
                        }
                      },
                    )
                ),
                Stack(
                  children: [
                    Positioned(child: isLoading ? LoadingView() : SizedBox.shrink())
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

