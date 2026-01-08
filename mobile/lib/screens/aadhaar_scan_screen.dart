import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/aadhaar_service.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';

/// Aadhaar QR Scanner Screen
class AadhaarScanScreen extends StatefulWidget {
  final String? userId; // Pass user ID if linking to account

  const AadhaarScanScreen({super.key, this.userId});

  @override
  State<AadhaarScanScreen> createState() => _AadhaarScanScreenState();
}

class _AadhaarScanScreenState extends State<AadhaarScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final AadhaarService _aadhaarService = AadhaarService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Handle QR code detection from camera
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    // For mAadhaar QR, we need to process the image
    // The rawValue might be compressed data
    _showProcessingDialog();
    
    // Note: For proper implementation, you'd capture the image and send to backend
    // Here we show a message that image upload is preferred for Aadhaar QR
    
    Navigator.pop(context); // Close processing dialog
    _showImageUploadRecommendation();
  }

  /// Show recommendation to use image upload
  void _showImageUploadRecommendation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Use Image Upload'),
          ],
        ),
        content: const Text(
          'For best results with mAadhaar QR codes, please upload an image or screenshot of the QR code instead of scanning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text('Upload Image'),
          ),
        ],
      ),
    );
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        await _processQRImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  /// Capture image from camera
  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        await _processQRImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  /// Process QR image through backend
  Future<void> _processQRImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    _showProcessingDialog();

    try {
      final result = await _aadhaarService.verifyQRImage(imageFile);

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      setState(() {
        _isProcessing = false;
      });

      if (result.success) {
        _showResultDialog(result);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Verification failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  /// Show processing dialog
  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Verifying Aadhaar QR...'),
            SizedBox(height: 8),
            Text(
              'Please wait while we process your QR code',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Show verification result dialog
  void _showResultDialog(AadhaarVerificationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.verified ? Icons.verified : Icons.warning,
              color: result.verified ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(result.verified ? 'Verified!' : 'Verification Pending'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.data?.name != null) ...[
                _buildInfoRow('Name', result.data!.name!),
                const Divider(),
              ],
              if (result.data?.uidLastFour != null) ...[
                _buildInfoRow('Aadhaar', 'XXXX XXXX ${result.data!.uidLastFour}'),
                const Divider(),
              ],
              if (result.data?.gender != null) ...[
                _buildInfoRow('Gender', result.data!.gender!),
                const Divider(),
              ],
              if (result.data?.dateOfBirth != null) ...[
                _buildInfoRow('DOB', result.data!.dateOfBirth!),
                const Divider(),
              ],
              if (result.referenceId != null) ...[
                  _buildInfoRow('Reference ID', result.referenceId!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (result.verificationToken != null) {
                // Navigate to register screen with verification data
                Navigator.of(context).pushReplacement(
                   MaterialPageRoute(
                     builder: (context) => RegisterScreen(
                       verificationToken: result.verificationToken,
                       verifiedName: result.data?.name,
                     ),
                   ),
                );
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Verification token missing. Please try again.')),
                 );
              }
            },
            child: const Text('Continue to Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Link Aadhaar to account
  Future<void> _linkAadhaar() async {
    // Implementation for linking - would need the image file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aadhaar linking will be implemented with backend integration'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  /// Toggle flashlight
  void _toggleFlash() {
    _scannerController.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  /// Switch camera
  void _switchCamera() {
    _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Aadhaar QR'),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? AppColors.warning : Colors.white,
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      body: Column(
        children: [
          // QR Scanner
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Scan overlay
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Corner decorations
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  left: MediaQuery.of(context).size.width * 0.5 - 140,
                  child: _buildCorner(true, true),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  right: MediaQuery.of(context).size.width * 0.5 - 140,
                  child: _buildCorner(true, false),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.25,
                  left: MediaQuery.of(context).size.width * 0.5 - 140,
                  child: _buildCorner(false, true),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.25,
                  right: MediaQuery.of(context).size.width * 0.5 - 140,
                  child: _buildCorner(false, false),
                ),
              ],
            ),
          ),

          // Bottom section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan mAadhaar QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open mAadhaar app and generate a QR code, then scan it here or upload an image.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _captureImage,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Camera', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build corner decoration for scan area
  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
