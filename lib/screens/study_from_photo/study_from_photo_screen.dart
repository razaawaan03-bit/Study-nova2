import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'study_analysis_screen.dart';
import 'web_camera_capture.dart';

class StudyFromPhotoScreen extends StatefulWidget {
  const StudyFromPhotoScreen({super.key});

  @override
  State<StudyFromPhotoScreen> createState() => _StudyFromPhotoScreenState();
}

class _StudyFromPhotoScreenState extends State<StudyFromPhotoScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study From Photo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section with icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.image, size: 50, color: Colors.blue.shade700),
              ),
            ),
            const SizedBox(height: 24),

            // Title and subtitle
            Center(
              child: Column(
                children: [
                  Text(
                    'Capture Your Study Material',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take or upload photos of textbooks, notes, diagrams, and other study materials to get instant explanations.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Visible loading state: the student can see that the camera or
            // gallery is opening, instead of the buttons just going dead.
            if (_isLoading) ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Opening...'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Main action buttons
            _buildActionButton(
              context,
              icon: Icons.camera_alt,
              title: 'Take a Photo',
              subtitle: 'Use your camera to capture study material',
              onTap: _takePhoto,
              isPrimary: true,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              context,
              icon: Icons.image_search,
              title: 'Choose from Gallery',
              subtitle: 'Pick an image from your device',
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 48),

            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ What you can photograph:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoPoint(context, 'Textbook pages'),
                  _buildInfoPoint(context, 'Handwritten notes'),
                  _buildInfoPoint(context, 'Diagrams and illustrations'),
                  _buildInfoPoint(context, 'Questions and problems'),
                  _buildInfoPoint(context, 'Charts and graphs'),
                  _buildInfoPoint(context, 'Any educational content'),
                  const SizedBox(height: 12),
                  Text(
                    '💡 Tip: Make sure the image is clear and well-lit for best results.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.blue.shade300 : Colors.grey.shade300,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isPrimary
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: isPrimary ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (mounted && _isLoading) return;

    if (kIsWeb) {
      await _captureFromWebCamera();
      return;
    }

    await _selectImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    await _selectImage(ImageSource.gallery);
  }

  Future<void> _captureFromWebCamera() async {
    setState(() => _isLoading = true);

    try {
      final captured = await launchWebCameraCapture(context);
      if (captured == null) {
        return;
      }

      if (captured.isEmpty) {
        _showMessage(
          'The captured image is empty or unreadable. Please try again.',
        );
        return;
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyAnalysisScreen(
            imageBytes: captured,
            fileName: 'webcam_capture.jpg',
          ),
        ),
      );
    } catch (error) {
      final message = error is StateError
          ? error.message
          : 'Could not open the webcam. Please try again.';
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Picks an image and opens the analysis screen with its raw bytes.
  ///
  /// Reading the bytes here (instead of passing a `File`) keeps this flow
  /// working on Flutter Web too, where `XFile.path` is a `blob:` URL and
  /// `dart:io`/`Image.file` are not supported.
  Future<void> _selectImage(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      // User cancelled the camera/gallery picker - nothing to do.
      if (picked == null) {
        return;
      }

      final Uint8List imageBytes = await picked.readAsBytes();

      if (imageBytes.isEmpty) {
        _showMessage(
          'The selected image is empty or unreadable. '
          'Please choose another image.',
        );
        return;
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyAnalysisScreen(
            imageBytes: imageBytes,
            fileName: _fileNameFor(picked),
          ),
        ),
      );
    } catch (e) {
      // A denied permission, a device with no camera app and a failed read all
      // land here. The student gets one clear sentence and can simply tap the
      // button again.
      _showMessage(_messageFor(source));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// A student-readable message for a failed pick.
  String _messageFor(ImageSource source) {
    if (source == ImageSource.camera) {
      return 'The camera could not be opened. Check that the app is allowed '
          'to use the camera, or choose an image from your gallery instead.';
    }
    return 'Could not load the selected image. Please try again.';
  }

  /// Resolves a usable file name for the picked image.
  ///
  /// `XFile.name` is available on every platform; on web it is the original
  /// browser file name. `path` is only used as a fallback since it is a
  /// `blob:` object URL on the web.
  String _fileNameFor(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) return name;

    final path = file.path.trim();
    if (path.isNotEmpty) {
      final segment = path.split('/').last;
      if (segment.isNotEmpty) return segment;
    }

    return 'study_image.jpg';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
