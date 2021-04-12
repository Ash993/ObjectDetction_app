import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main(){
  runApp(MyApp());
}
const String ssd ="SSD MobileNet";
const String yolo ="Tiny YOLOv2";

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {


  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {

  String _model =ssd;
  File _image;
  final picker = ImagePicker();

  double _imageWidth;
  double _imageHeight;
  bool _busy =false;

  List _recognitions;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _busy=true;
    loadModel().then((val){
      setState(() {
        _busy=false;
      });
    });
  }

  loadModel()async{
    Tflite.close();
    try{
      String res;
      if(_model==yolo){
        res=await Tflite.loadModel(
          model: "assets/tflite/yolov2_tiny.tflite",
          labels: "assets/tflite/yolov2_tiny",

        );

      }else{
        res=await Tflite.loadModel(
          model: "assets/tflite/ssd_mobilenet.tflite",
          labels: "assets/tflite/ssd_mobilenet",

        );

      }
      print(res);
    } on PlatformException{
      print("Failed to load the model");
    }
  }




  selectFromImagePicker() async{
    var image =await picker.getImage(source: ImageSource.gallery);
    if(image==null)return;
    setState(() {
      _busy =true;

    });
    predictImage(image);
  }
  predictImage(image)async{
    if(image==null) return;

    if(_model == yolo){
      await yolov2Tiny(image);
    }else{
      await ssdMobileNet(image);
    }
    
    FileImage(image).resolve(ImageConfiguration()).addListener((ImageStreamListener((ImageInfo info, bool _){
      setState(() {
        _imageWidth =info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
      });
    })));
    setState(() {
      _image =image;
      _busy =false;
    });
  }

  yolov2Tiny(image)async{
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
      model: "YOLO",
      threshold: 0.1,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1
    );

    setState(() {
      _recognitions= recognitions;
    });

  }

  ssdMobileNet(image) async{
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        numResultsPerClass: 1
    );

    setState(() {
      _recognitions= recognitions;
    });

  }
  List<Widget> renderBoxes(Size screen){
    if(_recognitions ==null) return [];
    if(_imageWidth ==null || _imageHeight ==null) return  [];

    double factorX =screen.width;
    double factorY=_imageHeight/_imageWidth*screen.width;

    Color blue= Colors.blue;

    return _recognitions.map((re){
      return Positioned(
      left: re['rect']['x']*factorX,
      top: re['rect']['y']*factorY,
      width: re['rect']['w']*factorX,
      height: re['rect']['h']*factorY,
      child: Container(
        decoration: BoxDecoration(border: Border.all(
          color: blue,
          width:3,
    )),
    child: Text('${re['detectedClass']} ${(re['confidenceInClass']=100).toStringAsFixed(0)}%',
        style: TextStyle(
        background: Paint()..color=blue,
    color: Colors.white,
    fontSize: 15,
    ),
    ),
    ),

      );
    }).toList();

  }

  @override
  Widget build(BuildContext context) {
    
    Size size =MediaQuery.of(context).size;
    
    List<Widget> stackChildren =[];
    
    stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,

        child: _image ==null? Padding(padding: EdgeInsets.all(16.0),
        child: Text("No Image Selected",style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.brown),)) : Image.file(_image),
    ));
    stackChildren.addAll(renderBoxes(size));

    if(_busy){
      stackChildren.add(Center(
        child: CircularProgressIndicator()));

    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detection App"),

      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        tooltip: "Pick Image from Gallery",
        onPressed: selectFromImagePicker ,
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }
}

