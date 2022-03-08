import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/allConstants/constants.dart';
import 'package:ichat_app/allModels/messageChat.dart';
import 'package:ichat_app/allProvider/settingsProvider.dart';
import 'package:ichat_app/allScreens/fullPhotoPage.dart';
import 'package:ichat_app/allScreens/loginPage.dart';
import 'dart:io';
import 'package:ichat_app/main.dart';
import 'package:ichat_app/allProvider/chatProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../allProvider/authProvider.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  ChatPage({required this.peerId, required this.peerNickname, required this.peerAvatar});

  @override
  State<ChatPage> createState() => ChatPageState(
    peerId: this.peerId,
    peerAvatar: this.peerAvatar,
    peerNickname: this.peerNickname
  );
}

class ChatPageState extends State<ChatPage> {

  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  ChatPageState({required this.peerId, required this.peerAvatar, required this.peerNickname});

  List<DocumentSnapshot> listMessage = List.from([]);

  int _limit = 20;
  int limitIncrement = 20;
  String groupChatId = "";
  String currentUserId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  onFocusChange(){
    if(focusNode.hasFocus){
      setState(() {
        isShowSticker = false;
      });
    }
  }

  _scrollListener(){
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState(() {
        _limit += limitIncrement;
      });
    }
  }

  readLocal(){
    if(authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }else{
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false
      );
    }

    if(currentUserId.hashCode >= peerId.hashCode){
      groupChatId = "$currentUserId-$peerId";
    }else{
      groupChatId = "$peerId-$currentUserId";
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId}
    );
  }

  void onSendMessage(String content, int type){
    if(content.isNotEmpty){
      chatProvider.sendMessage(currentUserId, peerId, groupChatId, content, type);
      textEditingController.clear();
      listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }else{
      Fluttertoast.showToast(msg: "Nothing sended..", textColor: Colors.grey);
    }
  }

  void uploadImageFile()async{
    String filename = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, filename);

    try{
      TaskSnapshot snapshot = uploadTask.snapshot;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    }on FirebaseException catch(e){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Future getImage()async{
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile;
    
    xFile = await imagePicker.pickImage(source: ImageSource.gallery);
    print(xFile.toString());
    if(xFile?.path != null) {
      imageFile = File(xFile!.path);
    }
    if(xFile != null){
      setState(() {
        isLoading = true;
      });
      uploadImageFile();
    }
  }

  bool isLastMessageLeft(int index){
    if((index > 0 && listMessage[index - 1].get(FirestoreConstants.idFrom) != currentUserId) || index == 0){
      return true;
    }else{
      return false;
    }
  }

  bool isLastMessageRight(int index){
    if((index > 0 && listMessage[index - 1].get(FirestoreConstants.idFrom) == currentUserId) || index == 0){
      return true;
    }else{
      return false;
    }
  }

  void getSticker(){
    setState(() {
      isShowSticker = !isShowSticker;
    });
    focusNode.unfocus();
  }

  Future<bool> onBackPress(){
    if(isShowSticker){
      setState(() {
        isShowSticker = false;
      });
    }else{
      chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: null}
      );
    }
    return Future.value(false);
  }

  void _callPhone(String phoneNum)async{
    String url = "tel://$phoneNum";
    if(await canLaunch(url)){
      try{
        await launch(url);
      }catch(e){
        print(e);
      }
    }else{
      Fluttertoast.showToast(msg: "Error occurred");
    }
  }

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white: Colors.grey,
        iconTheme: IconThemeData(color: ColorConstants.primaryColor),
        title: Text(peerNickname, style: TextStyle(color: ColorConstants.primaryColor),),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                Icons.phone_iphone,
              size: 30,
              color: ColorConstants.primaryColor,
            ),
            onPressed: ()async{
              String phoneNum = "";
              FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
              await firebaseFirestore
                .collection(FirestoreConstants.pathUserCollection)
                .doc(peerId)
                .get()
                .then((value){
                  setState(() {
                    phoneNum = value.get(FirestoreConstants.phoneNumber) ?? "";
                  });
                });
              print(phoneNum);
              _callPhone(phoneNum);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              buildMessageList(),
              isShowSticker ? buildSticker() : SizedBox.shrink(),
              buildInput(),
            ],
          )
        ],
      ),
    );
  }

  Widget buildSticker(){
    return Expanded(
        child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => onSendMessage("mimi1", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi1.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi2", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi2.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi3", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi3.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => onSendMessage("mimi4", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi4.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi5", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi5.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi6", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi6.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => onSendMessage("mimi7", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi7.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi8", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi8.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSendMessage("mimi9", TypeMessage.sticker),
                    child: Image.asset(
                      "images/mimi9.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(width: 0.5, color: ColorConstants.greyColor)),
            color: Colors.white
          ),
        ),
    );
  }

  Widget buildInput(){
    return Container(
      child: Row(
        children: [
          Material(
            child: Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                onPressed: getImage,
                icon: Icon(Icons.camera_enhance),
              ),
            ),
          ),
          Material(
            child: Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                onPressed: getSticker,
                icon: Icon(Icons.face_retouching_natural),
              ),
            ),
          ),
          Flexible(
              child: Center(
                child: Material(
                  child: TextField(
                    onSubmitted: (value) => onSendMessage(textEditingController.text, TypeMessage.text),
                    controller: textEditingController,
                    style: TextStyle(color: ColorConstants.primaryColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Message",
                      hintStyle: TextStyle(color: ColorConstants.greyColor)
                    ),
                    focusNode: focusNode,
                  ),
                ),
              )
          ),
          Material(
            child: Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                onPressed: () => onSendMessage(textEditingController.text, TypeMessage.text),
                icon: Icon(Icons.send),
              ),
            ),
          ),
        ],
      ),
      width: double.infinity,
      height: 50,
    );
  }

  Widget buildItem(int index, DocumentSnapshot? doc){
    if(doc != null){
      MessageChat messageChat = MessageChat.fromDoc(doc);
      listMessage.add(doc);
      if(messageChat.idFrom == currentUserId){
        return Row(
          children: [
            messageChat.type == TypeMessage.text ?
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: ColorConstants.greyColor2,
                  ),
                  child: Text(messageChat.content, style: TextStyle(color: ColorConstants.primaryColor),),
                  padding: EdgeInsets.fromLTRB(15, 10, 10, 15),
                  margin: EdgeInsets.only(top: isLastMessageRight(index) ? 20 : 10, right: 10),
                ) : messageChat.type == TypeMessage.image ?
            Container(
              child: OutlinedButton(
                child: Material(
                  child: Image.network(
                      messageChat.content,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null){
                          return child;
                        }else{
                          return Container(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null && loadingProgress.cumulativeBytesLoaded != null ?
                                  loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                              ),
                            ),
                          );
                        }
                    },
                    errorBuilder: (context, object, stackTrace){
                        return Material(
                          child: Image.asset(
                              "images/img_not_available.jpeg",
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          clipBehavior: Clip.hardEdge,//???
                        );
                    },
                  ),
                ),
                onPressed: () {
                  MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content));
                },
              ),
            ) : Container(
              child: Image.asset(
                  "images/${messageChat.content}.gif",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        );
      }else{
        return Container(
          child: Column(
            children: [
              Row(
                children: [
                  isLastMessageLeft(index) ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      borderRadius: BorderRadius.circular(100),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        peerAvatar,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                          if(loadingProgress == null){
                            return child;
                          }else{
                            return Container(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null && loadingProgress.cumulativeBytesLoaded != null ?
                                  loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                ),
                              ),
                            );
                          }
                        },
                        errorBuilder: (context, object, stackTrace){
                          return Material(
                            child: Icon(Icons.account_circle, size: 35, color: Colors.grey,),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            clipBehavior: Clip.hardEdge,//???
                          );
                        },
                      ),
                    ),
                  ) : Container(width: 35,),
                  messageChat.type == TypeMessage.text ?
                  Container(
                    child: Text(messageChat.content, style: TextStyle(color: Colors.white),),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: ColorConstants.primaryColor,
                    ),
                    padding: EdgeInsets.fromLTRB(15, 10, 10, 15),
                    margin: EdgeInsets.only(left: 10),
                  ) : messageChat.type == TypeMessage.image ?
                  Container(
                    child: TextButton(
                      child: Material(
                        child: Image.network(
                          messageChat.content,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                            if(loadingProgress == null){
                              return child;
                            }else{
                              return Container(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null && loadingProgress.cumulativeBytesLoaded != null ?
                                    loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                  ),
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, object, stackTrace){
                            return Material(
                              child: Image.asset(
                                "images/img_not_available.jpeg",
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                              clipBehavior: Clip.hardEdge,//???
                            );
                          },
                        ),
                      ),
                      onPressed: () {
                        MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content));
                      },
                    ),
                  ) : Container(
                    child: Image.asset(
                      "images/${messageChat.content}.gif",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              isLastMessageLeft(index) ?
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      child: Text(
                        DateFormat("dd MMM hh:mm")
                            .format(DateTime.fromMicrosecondsSinceEpoch(int.parse(messageChat.timestamp))),
                        style: TextStyle(color: ColorConstants.greyColor, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      margin: EdgeInsets.fromLTRB(50, 5, 0, 5),
                    ),
                  ) : SizedBox.shrink()
            ],
          ),
        );
      }
    }else{
      return SizedBox.shrink();
    }
  }

  Widget buildMessageList(){
    return Flexible(
        child: groupChatId.isNotEmpty ?
        StreamBuilder(
          stream: chatProvider.getChatStream(_limit, groupChatId),
            builder:(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
              if(snapshot.hasData){
                return ListView.builder(
                  itemBuilder: (context, index) => buildItem(index, snapshot.data?.docs[index]),
                  itemCount: snapshot.data?.docs.length,
                  reverse: false,
                  controller: listScrollController,
                );
              }else{
                return Center(child: CircularProgressIndicator());
              }
            }
        ) : Center(child: CircularProgressIndicator()),
    );
  }
}
