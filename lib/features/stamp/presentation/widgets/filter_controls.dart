import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';

class FilterControls extends ConsumerWidget {
  const FilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stampEditorProvider);
    final filter = state.style.filter;
    final notifier = ref.read(stampEditorProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AKTIFKAN FILTER VINTAGE', style: textStyle),
              Switch(
                value: filter.enabled,
                activeColor: activeColor,
                onChanged: (val) => notifier.setFilterEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filter.enabled) ...[
            // Filter Intensity
            Text('INTENSITAS (${(filter.intensity * 100).toInt()}%)', style: textStyle),
            Slider(
              value: filter.intensity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: activeColor,
              onChanged: (val) => notifier.setFilterIntensity(val),
            ),
            const SizedBox(height: 12),

            // Warmth (Kehangatan)
            Text('KEHANGATAN (WARMTH) (${(filter.warmth * 100).toInt()}%)', style: textStyle),
            Slider(
              value: filter.warmth,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: activeColor,
              onChanged: (val) => notifier.setFilterWarmth(val),
            ),
            const SizedBox(height: 12),

            // Sepia
            Text('SEPIA (${(filter.sepia * 100).toInt()}%)', style: textStyle),
            Slider(
              value: filter.sepia,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: activeColor,
              onChanged: (val) => notifier.setFilterSepia(val),
            ),
            const SizedBox(height: 12),

            // Grain (Noise)
            Text('GRAIN (NOISE KERTAS) (${(filter.grain * 100).toInt()}%)', style: textStyle),
            Slider(
              value: filter.grain,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: activeColor,
              onChanged: (val) => notifier.setFilterGrain(val),
            ),
            const SizedBox(height: 12),

            // Vignette (Tepi Gelap)
            Text('VIGNETTE (TEPI GELAP) (${(filter.vignette * 100).toInt()}%)', style: textStyle),
            Slider(
              value: filter.vignette,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: activeColor,
              onChanged: (val) => notifier.setFilterVignette(val),
            ),
          ],
        ],
      ),
    );
  }
}
