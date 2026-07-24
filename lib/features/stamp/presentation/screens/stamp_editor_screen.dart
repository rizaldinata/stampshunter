import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/border_controls.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/filter_controls.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/save_dialog.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/stamp_preview.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/template_picker.dart';
import 'package:stampshunter/features/stamp/presentation/widgets/text_editor.dart';

class StampEditorScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  const StampEditorScreen({super.key, this.imagePath});

  @override
  ConsumerState<StampEditorScreen> createState() => _StampEditorScreenState();
}

class _StampEditorScreenState extends ConsumerState<StampEditorScreen> {
  String _activeTab = 'border'; // border, filter, template, text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.imagePath != null) {
        ref.read(stampEditorProvider.notifier).setImagePath(widget.imagePath!);
      }
    });
  }

  void _showSaveDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SaveDialog(
          onSave: (title, description, tags, isPublic) async {
            Navigator.pop(dialogContext); // Close save dialog
            
            final notifier = ref.read(stampEditorProvider.notifier);

            final stamp = await notifier.save(
              title: title,
              description: description,
              tags: tags,
              isPublic: isPublic,
            );

            if (stamp != null) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Stamp digital berhasil disimpan!'),
                  backgroundColor: Colors.green,
                ),
              );
              router.go('/profile/me');
            } else {
              final state = ref.read(stampEditorProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Gagal menyimpan stamp.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActiveControls() {
    switch (_activeTab) {
      case 'filter':
        return const FilterControls();
      case 'template':
        return const TemplatePicker();
      case 'text':
        return const TextEditor();
      case 'border':
      default:
        return const BorderControls();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stampEditorProvider);
    final notifier = ref.read(stampEditorProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF9);
    final bottomBg = isDark ? Colors.black : Colors.white;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    if (widget.imagePath == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('BUAT STAMP')),
        body: const Center(child: Text('Tidak ada gambar terpilih.')),
      );
    }

    final canUndo = state.historyIndex > 0;
    final canRedo = state.historyIndex < state.history.length - 1;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            title: Text(
              'BUAT STAMP',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            actions: [
              // Undo Action
              IconButton(
                icon: Icon(
                  Icons.undo,
                  color: canUndo ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.grey.withOpacity(0.5),
                ),
                onPressed: canUndo ? notifier.undo : null,
                tooltip: 'Undo',
              ),
              // Redo Action
              IconButton(
                icon: Icon(
                  Icons.redo,
                  color: canRedo ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.grey.withOpacity(0.5),
                ),
                onPressed: canRedo ? notifier.redo : null,
                tooltip: 'Redo',
              ),
              // Reset Action
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: notifier.reset,
                tooltip: 'Reset',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // 1. Interactive Preview Section
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: SingleChildScrollView(
                      child: StampPreview(
                        imagePath: widget.imagePath!,
                        style: state.style,
                        size: 280.0,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Tab Bar Selector
              Container(
                decoration: BoxDecoration(
                  color: bottomBg,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.outlineDark : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabButton(
                      id: 'border',
                      icon: Icons.border_outer_rounded,
                      label: 'GERIGI',
                      activeColor: activeColor,
                    ),
                    _buildTabButton(
                      id: 'filter',
                      icon: Icons.photo_filter_rounded,
                      label: 'FILTER',
                      activeColor: activeColor,
                    ),
                    _buildTabButton(
                      id: 'template',
                      icon: Icons.layers_outlined,
                      label: 'BINGKAI',
                      activeColor: activeColor,
                    ),
                    _buildTabButton(
                      id: 'text',
                      icon: Icons.text_fields_rounded,
                      label: 'TEKS',
                      activeColor: activeColor,
                    ),
                  ],
                ),
              ),

              // 3. Dynamic Controls Section
              Expanded(
                flex: 3,
                child: Container(
                  color: bottomBg,
                  child: _buildActiveControls(),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: activeColor,
            foregroundColor: Colors.black,
            onPressed: _showSaveDialog,
            tooltip: 'Simpan Stamp',
            child: const Icon(Icons.check_rounded, size: 28),
          ),
        ),

        // 4. Loading/Processing Overlay
        if (state.isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MEMPROSES STAMP...',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton({
    required String id,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _activeTab == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isSelected
        ? activeColor
        : (isDark ? Colors.white60 : AppColors.textTertiary);

    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
