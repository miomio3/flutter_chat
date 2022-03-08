import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ichat_app/allConstants/constants.dart';

class UserChat{
  String id;
  String photoUrl;
  String nickname;
  String aboutMe;
  String phoneNumber;

  UserChat({
   required this.id,
   required this.photoUrl,
   required this.nickname,
   required this.aboutMe,
   required this.phoneNumber
  });

  Map<String, String> toJson() =>
      {
        "id": this.id,
        "photoUrl": this.photoUrl,
        "nickname": this.nickname,
        "aboutMe": this.aboutMe,
        "phoneNumber": this.phoneNumber,
      };

  factory UserChat.fromDoc(DocumentSnapshot doc){
    String aboutMe = "";
    String photoUrl= "";
    String nickname= "";
    String phoneNumber= "";

    try{
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    }
    catch(e){
      print(e);
    }
    try{
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    }
    catch(e){
      print(e);
    }
    try{
      nickname = doc.get(FirestoreConstants.nickname);
    }
    catch(e){
      print(e);
    }
    try{
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    }
    catch(e){
      print(e);
    }
    return UserChat(
        id: doc.id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber
    );
  }

}