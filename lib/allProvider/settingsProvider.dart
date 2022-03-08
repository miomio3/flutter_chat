
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SettingsProvider{
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  SettingsProvider({
    required this.prefs,
    required this.firebaseStorage,
    required this.firebaseFirestore,
  });

  String? getString(String key){
    return prefs.getString(key);
  }

  Future<bool> setPrefs(String key, String value)async{
    return await prefs.setString(key, value);
  }

  UploadTask uploadFile(File image, String filename){
    Reference ref = firebaseStorage.ref().child(filename);
    return ref.putFile(image);
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, String> data){
    return firebaseFirestore.collection(collectionPath).doc(docPath).update(data);
  }
}