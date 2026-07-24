import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';

class TextEditor extends ConsumerStatefulWidget {
  const TextEditor({super.key});

  @override
  ConsumerState<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends ConsumerState<TextEditor> {
  int _editingIndex = -1; // -1 means we are not editing/creating a text
  final _textController = TextEditingController();
  String _position = 'bottom';
  String _fontFamily = 'serif';
  double _fontSize = 24.0;
  Color _fontColor = Colors.black;

  final List<String> _positions = ['top', 'bottom', 'left', 'right', 'center'];
  final List<String> _fonts = ['serif', 'sans-serif', 'monospace', 'readable', 'script'];

  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startEditing(int index, TextOverlayConfig config) {
    setState(() {
      _editingIndex = index;
      _textController.text = config.content;
      _position = config.position;
      _fontFamily = config.fontFamily;
      _fontSize = config.fontSize;
      _fontColor = config.fontColor;
    });
  }

  void _startNew() {
    setState(() {
      _editingIndex = 999; // Arbitrary high index representing new text overlay
      _textController.clear();
      _position = 'bottom';
      _fontFamily = 'serif';
      _fontSize = 24.0;
      _fontColor = Colors.black;
    });
  }

  void _save() {
    if (_textController.text.trim().isEmpty) return;

    final config = TextOverlayConfig(
      content: _textController.text.trim(),
      position: _position,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      fontColor: _fontColor,
    );

    final notifier = ref.read(stampEditorProvider.notifier);
    if (_editingIndex == 999) {
      notifier.addTextOverlay(config);
    } else {
      notifier.updateTextOverlay(_editingIndex, config);
    }

    setState(() {
      _editingIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stampEditorProvider);
    final textOverlays = state.style.textOverlays;
    final notifier = ref.read(stampEditorProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    if (_editingIndex != -1) {
      // Show form to Add or Edit text
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingIndex == 999 ? 'TAMBAH TEKS BARU' : 'EDIT TEKS',
                  style: textStyle.copyWith(color: activeColor),
                ),
                TextButton(
                  onPressed: () => setState(() => _editingIndex = -1),
                  child: const Text('Batal'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Input field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Tulis teks perangko...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Position selector
            Text('POSISI TEKS', style: textStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _positions.map((pos) {
                final isSelected = _position == pos;
                return ChoiceChip(
                  label: Text(pos.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _position = pos);
                  },
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Font Selector
            Text('JENIS HURUF', style: textStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _fonts.map((f) {
                final isSelected = _fontFamily == f;
                return ChoiceChip(
                  label: Text(f.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _fontFamily = f);
                  },
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Font Size
            Text('UKURAN HURUF (${_fontSize.toInt()} px)', style: textStyle),
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 48.0,
              divisions: 18,
              activeColor: activeColor,
              onChanged: (val) => setState(() => _fontSize = val),
            ),
            const SizedBox(height: 16),

            // Font Color Selector
            Text('WARNA TEKS', style: textStyle),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = _fontColor.value == color.value;

                  return GestureDetector(
                    onTap: () => setState(() => _fontColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.grey,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _save,
                child: const Text('TERAPKAN TEKS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // Show list of current Text Overlays
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AKTIFKAN OVERLAY TEKS', style: textStyle),
              Switch(
                value: state.style.textEnabled,
                activeColor: activeColor,
                onChanged: (val) => notifier.setTextEnabled(val),
              ),
            ],
          ),
        ),
        const Divider(),
        if (state.style.textEnabled) ...[
          Expanded(
            child: textOverlays.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada teks.\nKetuk tombol di bawah untuk menambah teks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: textOverlays.length,
                    itemBuilder: (context, index) {
                      final textConfig = textOverlays[index];
                      return Card(
                        color: isDark ? Colors.white12 : Colors.grey[100],
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(
                            textConfig.content.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Posisi: ${textConfig.position} | Font: ${textConfig.fontFamily}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _startEditing(index, textConfig),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                onPressed: () => notifier.removeTextOverlay(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('TAMBAH TEKS BARU', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: activeColor,
                  side: BorderSide(color: activeColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _startNew,
              ),
            ),
          ),
        ] else
          const Expanded(
            child: SizedBox(),
          ),
      ],
    );
  }
}
