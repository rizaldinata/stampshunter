import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stampshunter/features/camera/presentation/providers/stamp_image_picker_provider.dart';
import 'package:stampshunter/features/camera/presentation/widgets/camera_preview_widget.dart';
import 'package:stampshunter/shared/utils/stamp_snackbar.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _controller;

    // App to background -> dispose camera
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    }
    // App to foreground -> re-initialize
    else if (state == AppLifecycleState.resumed) {
      if (cameraController == null) {
        _checkPermissionAndInit();
      }
    }
  }

  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _initCamera();
    } else {
      final result = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasPermission = result.isGranted;
        });
        if (result.isGranted) {
          _initCamera();
        }
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          showStampSnackBar(
            context,
            message: 'Tidak ada kamera yang tersedia pada peranti ini.',
            type: StampSnackBarType.error,
          );
        }
        return;
      }

      // Initialize with selected camera index
      final camera = _cameras[_selectedCameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showStampSnackBar(
          context,
          message: 'Gagal menginisialisasi kamera: $e',
          type: StampSnackBarType.error,
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _disposeController();
    _initCamera();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isTakingPicture = true;
    });

    try {
      final file = await _controller!.takePicture();
      _processImage(file.path);
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      if (mounted) {
        showStampSnackBar(
          context,
          message: 'Gagal mengambil gambar: $e',
          type: StampSnackBarType.error,
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final notifier = ref.read(stampImagePickerProvider.notifier);
    final success = await notifier.pickFromGallery();
    
    if (success) {
      final selectedPath = ref.read(stampImagePickerProvider).selectedImagePath;
      if (selectedPath != null) {
        _processImage(selectedPath);
      }
    } else {
      final error = ref.read(stampImagePickerProvider).errorMessage;
      if (error != null && mounted) {
        showStampSnackBar(
          context,
          message: error,
          type: StampSnackBarType.error,
        );
      }
    }
  }

  Future<void> _processImage(String path) async {
    final notifier = ref.read(stampImagePickerProvider.notifier);
    final croppedPath = await notifier.cropImage(path);

    setState(() {
      _isTakingPicture = false;
    });

    if (croppedPath != null && mounted) {
      // Navigate to Stamp Editor with the cropped path
      context.pushReplacement('/stamp-editor', extra: croppedPath);
    } else {
      final error = ref.read(stampImagePickerProvider).errorMessage;
      if (error != null && mounted) {
        showStampSnackBar(
          context,
          message: error,
          type: StampSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Preview ──────────────────────────────────────────────────
          Positioned.fill(
            child: CameraPreviewWidget(
              controller: _controller,
              isInitialized: _isInitialized,
              hasPermission: _hasPermission,
              onRetryPermission: _checkPermissionAndInit,
            ),
          ),

          // ── Glassmorphic Top Overlay ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),

                      // Title
                      Text(
                        'AMBIL FOTO STAMP',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),

                      // Empty box for alignment
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Controls ────────────────────────────────────────────────
          if (_hasPermission && _isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 40, top: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery shortcut
                    _ControlButton(
                      icon: Icons.photo_library_outlined,
                      onPressed: _pickFromGallery,
                    ),

                    // Shutter button (custom stamp circular layout)
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFB300), // Amber border
                            width: 3.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isTakingPicture
                                ? const Color(0xFFFFB300).withValues(alpha: 0.5)
                                : Colors.white,
                          ),
                          child: _isTakingPicture
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Camera Switch
                    _ControlButton(
                      icon: Icons.flip_camera_ios_outlined,
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
