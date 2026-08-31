import 'package:image_picker/image_picker.dart';

class PhotoPickerService {
  PhotoPickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> pickFromCamera() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    return photo?.path;
  }

  Future<String?> pickFromGallery() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
    return photo?.path;
  }
}
