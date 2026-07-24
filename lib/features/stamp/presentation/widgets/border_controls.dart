import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';

class BorderControls extends ConsumerWidget {
  const BorderControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stampEditorProvider);
    final border = state.style.border;
    final notifier = ref.read(stampEditorProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    final presetColors = [
      Colors.white,
      const Color(0xFFFAF9F6), // Off-white
      const Color(0xFFF5F5DC), // Beige / Cream
      const Color(0xFFFFECEF), // Vintage Rose
      const Color(0xFFE3F2FD), // Vintage Blue
      const Color(0xFF0A0A0A), // Charcoal Black
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AKTIFKAN BORDER PERANGKO', style: textStyle),
              Switch(
                value: border.enabled,
                activeColor: activeColor,
                onChanged: (val) => notifier.setBorderEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (border.enabled) ...[
            // Tooth Size slider
            Text('UKURAN GERIGI (${border.toothSize} px)', style: textStyle),
            Slider(
              value: border.toothSize.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              activeColor: activeColor,
              onChanged: (val) => notifier.setToothSize(val.toInt()),
            ),
            const SizedBox(height: 12),

            // Tooth Spacing slider
            Text('JARAK GERIGI (${border.toothSpacing} px)', style: textStyle),
            Slider(
              value: border.toothSpacing.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              activeColor: activeColor,
              onChanged: (val) => notifier.setToothSpacing(val.toInt()),
            ),
            const SizedBox(height: 12),

            // Border Width slider
            Text('LEBAR BORDER (${border.borderWidth} px)', style: textStyle),
            Slider(
              value: border.borderWidth.toDouble(),
              min: 10,
              max: 40,
              divisions: 30,
              activeColor: activeColor,
              onChanged: (val) => notifier.setBorderWidth(val.toInt()),
            ),
            const SizedBox(height: 16),

            // Preset color selection
            Text('WARNA BORDER', style: textStyle),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: presetColors.length,
                itemBuilder: (context, index) {
                  final color = presetColors[index];
                  final isSelected = border.borderColor.value == color.value;

                  return GestureDetector(
                    onTap: () => notifier.setBorderColor(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          width: isSelected ? 3.0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
