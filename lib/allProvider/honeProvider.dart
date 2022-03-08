import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ichat_app/allConstants/constants.dart';

class HomeProvider{
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({required this.firebaseFirestore});

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, String> data){
    return firebaseFirestore.collection(collectionPath).doc(docPath).update(data);
  }

  Stream<QuerySnapshot> getStreamFirestore(String collectionPath, int limit, String? text){
    if(text?.isNotEmpty == true){
      return firebaseFirestore.collection(collectionPath).limit(limit).where(FirestoreConstants.nickname, isEqualTo: text).snapshots();
    }
    else{
      return firebaseFirestore.collection(collectionPath).limit(limit).snapshots();
    }
  }
}