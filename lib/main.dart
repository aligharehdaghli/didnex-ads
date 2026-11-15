import 'package:didnex/pages/home.dart';
import 'package:didnex_ads/didnex_ads.dart';
import 'package:flutter/material.dart';
 
void main() {
  runApp(
    DidnexAds.direct(
      packageName: 'com.example.didnex',
      adOrigin: Uri.parse('https://didnex.com'),
      child:  MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(),
        home: HomePage(),
      ),
    ),
  );
}
