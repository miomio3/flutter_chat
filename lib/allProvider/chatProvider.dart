import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ichat_app/allConstants/constants.dart';
import 'package:ichat_app/allModels/messageChat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ChatProvider{
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;
  final SharedPreferences prefs;

  ChatProvider({required this.firebaseFirestore, required this.firebaseStorage, required this.prefs});

  UploadTask uploadFile(File file, String filename){
    Reference reference = firebaseStorage.ref().child(filename);
    UploadTask uploadTask = reference.putFile(file);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> data){
    return firebaseFirestore.collection(collectionPath).doc(docPath).update(data);
  }

  Stream<QuerySnapshot> getChatStream(int limit, String groupChatId){
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp)
        .snapshots();
  }

  void sendMessage(String currentUserId, String peerId, String groupId, String content, int type){
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupId)
        .collection(groupId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    MessageChat messageChat = MessageChat(
        idFrom: currentUserId,
        idTo: peerId,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: type
    );

    FirebaseFirestore.instance.runTransaction((transaction)async{
      transaction.set(documentReference, messageChat.toJson());
    });


  }
}

class TypeMessage{
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}