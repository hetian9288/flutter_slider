import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_slider/flutter_slider.dart';

void main() => runApp(new IndexApp());

class IndexApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: MyApp(),
    );
  }

}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSliderController sliderController;

  @override
  void initState() {
    super.initState();
    sliderController = FlutterSliderController();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 300.0,
            child: FlutterSlider(
              scale: 0.15,
              width: MediaQuery.of(context).size.width,
              itemWidth: 230.0,
              initLeftOffset: 12.0,
              style: FlutterSliderStyle.n2,
              sliderController: sliderController,
              autoPlay: true,
              onDragUpdate: (double offset, double r){
                print(r);
              },
              children: <SliderItem>[
                SliderItem(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0),color: Colors.deepOrange),child: Center(child: Text("0"),), width: 230.0, height: 200.0,)),
                SliderItem(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0),color: Colors.amberAccent),child: Center(child: Text("1"),), width: 230.0, height: 200.0,)),
                SliderItem(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0),color: Colors.deepPurpleAccent),child: Center(child: Text("2"),), width: 230.0, height: 200.0,)),
                SliderItem(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0),color: Colors.red),child: Center(child: Text("3"),), width: 230.0, height: 200.0,)),
                SliderItem(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0),color: Colors.teal),child: Center(child: Text("4"),), width: 230.0, height: 200.0,)),
              ],
            )
          ),
          FlatButton(
            child: Text("上一个"),
            onPressed: (){
              sliderController.prev();
            }
          ),
          FlatButton(
            child: Text("下一个"),
            onPressed: (){
              sliderController.next();
            }
          ),
        ]
      ),
    );
  }
}
