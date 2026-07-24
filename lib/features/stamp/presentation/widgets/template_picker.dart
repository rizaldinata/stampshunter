import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';

class TemplatePicker extends ConsumerWidget {
  const TemplatePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stampEditorProvider);
    final template = state.style.template;
    final notifier = ref.read(stampEditorProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    // Dynamic predefined templates
    final templates = [
      const TemplateConfig(
        enabled: true,
        id: 'template_blue',
        frameColor: Color(0xFF87CEEB), // Sky Blue
      ),
      const TemplateConfig(
        enabled: true,
        id: 'template_gold',
        frameColor: Color(0xFFFFD700), // Gold
      ),
      const TemplateConfig(
        enabled: true,
        id: 'template_crimson',
        frameColor: Color(0xFFDC143C), // Crimson Red
      ),
      const TemplateConfig(
        enabled: true,
        id: 'template_forest',
        frameColor: Color(0xFF228B22), // Forest Green
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AKTIFKAN OVERLAY TEMPLATE', style: textStyle),
              Switch(
                value: template.enabled,
                activeColor: activeColor,
                onChanged: (val) => notifier.setTemplateEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (template.enabled) ...[
            Text('PILIH MODEL BINGKAI', style: textStyle),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  final isSelected = template.id == t.id;

                  return GestureDetector(
                    onTap: () => notifier.setTemplate(t),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black45 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Vector frame preview drawing inside picker
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: t.frameColor.withOpacity(0.8),
                                    width: 2.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 2,
                                      left: 2,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        color: t.frameColor,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        color: t.frameColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Selected Check Icon
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          // Label/Name
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Text(
                              t.id!.replaceFirst('template_', '').toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
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
