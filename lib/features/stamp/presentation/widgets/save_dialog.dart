import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';

class SaveDialog extends StatefulWidget {
  final Function(String title, String? description, List<String> tags, bool isPublic) onSave;

  const SaveDialog({super.key, required this.onSave});

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // Parse comma-separated tags
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isNotEmpty
          ? tagsText.split(',').map((t) => t.trim().replaceAll('#', '')).where((t) => t.isNotEmpty).toList()
          : <String>[];

      widget.onSave(title, description.isEmpty ? null : description, tags, _isPublic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMPAN STAMP DIGITAL',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 14,
                    color: activeColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Stamp *',
                    hintText: 'Masukkan judul stamp...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Ceritakan tentang stamp ini...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tags field
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Label/Tags (Koma terpisah)',
                    hintText: 'e.g. nature, travel, vintage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Public Visibility Switch
                SwitchListTile(
                  title: Text(
                    'Publikasikan Stamp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Agar bisa dilihat di feed oleh pengguna lain',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _isPublic,
                  activeColor: activeColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isPublic = val),
                ),
                const SizedBox(height: 24),

                // Dialog Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'BATAL',
                        style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(100, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'SIMPAN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
