import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/allConstants/app_constants.dart';
import 'package:ichat_app/allConstants/color_constants.dart';
import 'package:ichat_app/allConstants/constants.dart';
import 'package:ichat_app/allConstants/firestore_constants.dart';
import 'package:ichat_app/allModels/userChat.dart';
import 'package:ichat_app/allProvider/settingsProvider.dart';
import 'package:ichat_app/allScreens/homePage.dart';
import 'package:ichat_app/allWidgets/loading_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../main.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          AppConstants.appTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({Key? key}) : super(key: key);

  @override
  _SettingsPageStateState createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {

  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String dialCodeDigits = "+00";
  String id = "";
  String nickname = "";
  String aboutMe = "";
  String photoUrl= "";
  String phoneNumber= "";

  final TextEditingController _controller = TextEditingController();
  late SettingsProvider settingsProvider;
  bool isLoading = false;
  File? avatorImageFile;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  void readLocal()async{
    settingsProvider = await Provider.of<SettingsProvider>(context, listen: false);
    setState(() {
      id = settingsProvider.getString(FirestoreConstants.id) ?? "";
      nickname = settingsProvider.getString(FirestoreConstants.nickname) ?? "";
      aboutMe = settingsProvider.getString(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingsProvider.getString(FirestoreConstants.photoUrl) ?? "";
      phoneNumber = settingsProvider.getString(FirestoreConstants.phoneNumber) ?? "";
    });
    print("id = $id");
    print("aboutMe = $aboutMe");

    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future uploadFile()async{
    String filename = id;
    UploadTask uploadTask = settingsProvider.uploadFile(avatorImageFile!, filename);
    try{
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(
        id: this.id,
        nickname: this.nickname,
        aboutMe: this.aboutMe,
        photoUrl: this.photoUrl,
        phoneNumber: this.phoneNumber
      );

      settingsProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson()).then((value)async{
        await settingsProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      }).catchError((e){
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: e.toString());
      });
    }
    on FirebaseException catch(e){
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Future getImage()async{
    ImagePicker imagePicker = await ImagePicker();
    XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if(image != null){
      setState(() {
        avatorImageFile = File(image.path);
        isLoading = true;
      });
    }
    uploadFile();
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;

      if (dialCodeDigits != "+00" && _controller.text != "") {
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });

    UserChat updateInfo = UserChat(
        id: this.id,
        nickname: this.nickname,
        aboutMe: this.aboutMe,
        photoUrl: this.photoUrl,
        phoneNumber: this.phoneNumber
    );

    settingsProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson()).then((data) async {
      await settingsProvider.setPrefs(FirestoreConstants.nickname, nickname);
      await settingsProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);
      await settingsProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      await settingsProvider.setPrefs(FirestoreConstants.phoneNumber, phoneNumber);

      Fluttertoast.showToast(msg: "Update succeeded!");
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.toString());
    });
    setState(() {
      isLoading = false;
    });
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  @override
  Widget build(BuildContext context) {
    print(photoUrl);
    print(avatorImageFile?.path);
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                  onPressed: getImage,
                child: Container(
                  margin: EdgeInsets.all(20),
                  child: avatorImageFile == null ? photoUrl.isNotEmpty ?
                  ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      height: 90,
                      width: 90,
                      errorBuilder: (context, object, stackTrace){
                        return Icon(
                          Icons.account_circle,
                          size: 90,
                          color: ColorConstants.greyColor,
                        );
                      },
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null){
                          return child;
                        }
                        return Container(
                          width: 90,
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              value: loadingProgress.expectedTotalBytes != null && loadingProgress.cumulativeBytesLoaded != null ?
                              loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null ,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : Icon(Icons.account_circle, size: 90, color: ColorConstants.greyColor,)
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.file(
                      avatorImageFile!,
                      width: 90,
                      height: 90,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      "Name",
                      style: TextStyle(
                        fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.greyColor2)
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.greyColor)
                          ),
                          hintText: "Write your name...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor)
                        ),
                        controller: controllerNickname,
                        onChanged: (value){
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      "About me",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ColorConstants.greyColor2)
                            ),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ColorConstants.greyColor)
                            ),
                            hintText: "Write about yourself...",
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor)
                        ),
                        controller: controllerAboutMe,
                        onChanged: (value){
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      "Phone number",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country){
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: ["+1","US"],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ColorConstants.greyColor2)
                            ),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ColorConstants.greyColor)
                            ),
                            prefix: Text(dialCodeDigits, style: TextStyle(color: Colors.grey),),
                            hintText: phoneNumber,
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor)
                        ),
                        maxLength: 12,
                        keyboardType: TextInputType.number,
                        controller: _controller,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 50, bottom: 50),
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    "Update now",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.fromLTRB(30, 10, 30, 10)),
                  ),
                ),
              )
            ],
          ),
        ),
        Positioned(child: isLoading ? LoadingView() : SizedBox.shrink())
      ],
    );
  }
}
