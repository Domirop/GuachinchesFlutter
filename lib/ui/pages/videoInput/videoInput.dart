import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/ui/pages/videoInput/videoInputPresenter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart';

import '../../../data/RemoteRepository.dart';

class VideoInputPage extends StatefulWidget {
  final Function(MediaInfo) onVideoSelected;
  late String restaurantId ;

  VideoInputPage({required this.onVideoSelected, required this.restaurantId});

  @override
  _VideoInputPageState createState() => _VideoInputPageState();


}

class _VideoInputPageState extends State<VideoInputPage> implements VideoInputView{
  late VideoInputPresenter presenter;
  late RemoteRepository remoteRepository;
  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    presenter = VideoInputPresenter(remoteRepository,this);

  }
  final titleController = TextEditingController();
  MediaInfo? mediaInfo;
  String? base64Thumbnail;
  bool isVideoSelected = false;
  bool isLoadingVideo = false;
  bool isVideoUploading = false;
  Future<void> _pickAndCompressVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      isLoadingVideo = true;
    });
    if (pickedFile != null) {
      MediaInfo compressedVideo = await VideoCompress.compressVideo(
        pickedFile.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: false,
      ) as MediaInfo;

      final thumbnailFile = await VideoCompress.getByteThumbnail(
        pickedFile.path,
        quality: 50,
        position: -1,
      );

      img.Image? image = img.decodeImage(thumbnailFile!);
      if (image != null) {
        List<int> jpgBytes = img.encodeJpg(image, quality: 80);
        String base64String = base64Encode(jpgBytes);
        setState(() {
          mediaInfo = compressedVideo;
          base64Thumbnail = base64String;
          isVideoSelected = true;
        });
      }
      setState(() {
        isLoadingVideo = false;
      });
    }
  }

  void _confirmUpload() {
    setState(() {
      isVideoUploading = true;
    });
  presenter.saveVideo(
        mediaInfo!,
       titleController.text,
        widget.restaurantId,
       base64Thumbnail!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Video'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                  labelText: 'Título del Video'
              ),
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: _pickAndCompressVideo,
              child: Text('Seleccionar Video'),
            ),
            SizedBox(height: 10),
            isLoadingVideo
                ? CircularProgressIndicator()
                :Container(),
            if (isVideoSelected)
              Column(
                children: [
                  if (base64Thumbnail != null)
                    Image.memory(base64Decode(base64Thumbnail!),height: 200,),
                  SizedBox(height: 10),

                  isVideoUploading?
                      Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Subiendo Video... Puede tardar unos varios minutos. Puedes cerrar esta pantalla'),
                        ],
                      )
                      :ElevatedButton(
                    onPressed: _confirmUpload,
                    child: Text('Confirmar Subida'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  uploadConfirm() {
    widget.onVideoSelected(mediaInfo!);
    Navigator.pop(context);
  }
}