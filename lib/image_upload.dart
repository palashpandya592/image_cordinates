import 'package:flutter/material.dart';
import 'package:image_coordinatesdemo/zoomable_cached_image.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadClass extends StatefulWidget {
  const ImageUploadClass({Key? key}) : super(key: key);

  @override
  _ImageUploadClassState createState() => _ImageUploadClassState();
}

class _ImageUploadClassState extends State<ImageUploadClass> {
  final ImagePicker _picker = ImagePicker();
  double? posX, posY;
  XFile? _imageFileList;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text("Upload Image"),
      ),
      body: Container(
        height: size.height,
        width: size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _onImageButtonPressed(ImageSource.gallery, context: context);
                },
                child: const Text("Upload Image"),
              ),
              if (_imageFileList != null) _previewImages()
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewImages() {
    if (_imageFileList != null) {
      return InteractiveViewer(
        key: key,
        panEnabled: true,
        // Set it to false to prevent panning.
        minScale: 0.5,
        maxScale: 4,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) => onTapDown(context, details),
          child: ZoomableCachedImage(_imageFileList!.path),
        ),
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  void onTapDown(BuildContext context, TapDownDetails details) {
    RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
    Offset position =
        box.globalToLocal(details.globalPosition); //this is global position
    _showSnackBar("coordinates ${position.dx} and ${position.dy}");
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      setState(() {
        _imageFileList = pickedFile;
      });
    } catch (e) {}
  }
}
