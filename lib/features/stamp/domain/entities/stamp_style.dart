import 'package:flutter/material.dart';

class BorderConfig {
  final bool enabled;
  final int toothSize;
  final int toothSpacing;
  final int borderWidth;
  final Color borderColor;

  const BorderConfig({
    this.enabled = true,
    this.toothSize = 10,
    this.toothSpacing = 5,
    this.borderWidth = 20,
    this.borderColor = Colors.white,
  });

  BorderConfig copyWith({
    bool? enabled,
    int? toothSize,
    int? toothSpacing,
    int? borderWidth,
    Color? borderColor,
  }) {
    return BorderConfig(
      enabled: enabled ?? this.enabled,
      toothSize: toothSize ?? this.toothSize,
      toothSpacing: toothSpacing ?? this.toothSpacing,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  factory BorderConfig.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>? ?? {};
    return BorderConfig(
      enabled: json['enabled'] ?? true,
      toothSize: config['tooth_size'] ?? 10,
      toothSpacing: config['tooth_spacing'] ?? 5,
      borderWidth: config['border_width'] ?? 20,
      borderColor: _parseHexColor(config['border_color'] ?? '#FFFFFF'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'config': {
        'tooth_size': toothSize,
        'tooth_spacing': toothSpacing,
        'border_width': borderWidth,
        'border_color': _toHexColor(borderColor),
      }
    };
  }
}

class FilterConfig {
  final bool enabled;
  final double intensity;
  final double warmth;
  final double grain;
  final double vignette;
  final double sepia;

  const FilterConfig({
    this.enabled = true,
    this.intensity = 0.7,
    this.warmth = 0.5,
    this.grain = 0.3,
    this.vignette = 0.4,
    this.sepia = 0.0,
  });

  FilterConfig copyWith({
    bool? enabled,
    double? intensity,
    double? warmth,
    double? grain,
    double? vignette,
    double? sepia,
  }) {
    return FilterConfig(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      warmth: warmth ?? this.warmth,
      grain: grain ?? this.grain,
      vignette: vignette ?? this.vignette,
      sepia: sepia ?? this.sepia,
    );
  }

  factory FilterConfig.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>? ?? {};
    return FilterConfig(
      enabled: json['enabled'] ?? true,
      intensity: (config['intensity'] ?? 0.7).toDouble(),
      warmth: (config['warmth'] ?? 0.5).toDouble(),
      grain: (config['grain'] ?? 0.3).toDouble(),
      vignette: (config['vignette'] ?? 0.4).toDouble(),
      sepia: (config['sepia'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'config': {
        'intensity': intensity,
        'warmth': warmth,
        'grain': grain,
        'vignette': vignette,
        'sepia': sepia,
      }
    };
  }
}

class TemplateConfig {
  final bool enabled;
  final String? id;
  final String? overlayUrl;
  final Color frameColor;

  const TemplateConfig({
    this.enabled = false,
    this.id,
    this.overlayUrl,
    this.frameColor = const Color(0xFF87CEEB), // #87CEEB (Sky Blue)
  });

  TemplateConfig copyWith({
    bool? enabled,
    String? id,
    String? overlayUrl,
    Color? frameColor,
  }) {
    return TemplateConfig(
      enabled: enabled ?? this.enabled,
      id: id ?? this.id,
      overlayUrl: overlayUrl ?? this.overlayUrl,
      frameColor: frameColor ?? this.frameColor,
    );
  }

  factory TemplateConfig.fromJson(Map<String, dynamic> json) {
    return TemplateConfig(
      enabled: json['enabled'] ?? false,
      id: json['id'],
      overlayUrl: json['overlay_url'],
      frameColor: _parseHexColor(json['frame_color'] ?? '#87CEEB'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'id': id,
      'overlay_url': overlayUrl,
      'frame_color': _toHexColor(frameColor),
    };
  }
}

class TextOverlayConfig {
  final String content;
  final String position; // top, bottom, left, right, center
  final String fontFamily; // serif, sans-serif, monospace, readable, script
  final double fontSize;
  final Color fontColor;
  final int margin;

  const TextOverlayConfig({
    this.content = '',
    this.position = 'bottom',
    this.fontFamily = 'serif',
    this.fontSize = 24.0,
    this.fontColor = Colors.black,
    this.margin = 20,
  });

  TextOverlayConfig copyWith({
    String? content,
    String? position,
    String? fontFamily,
    double? fontSize,
    Color? fontColor,
    int? margin,
  }) {
    return TextOverlayConfig(
      content: content ?? this.content,
      position: position ?? this.position,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      margin: margin ?? this.margin,
    );
  }

  factory TextOverlayConfig.fromJson(Map<String, dynamic> json) {
    return TextOverlayConfig(
      content: json['content'] ?? '',
      position: json['position'] ?? 'bottom',
      fontFamily: json['font_family'] ?? 'serif',
      fontSize: (json['font_size'] ?? 24.0).toDouble(),
      fontColor: _parseHexColor(json['font_color'] ?? '#000000'),
      margin: json['margin'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'position': position,
      'font_family': fontFamily,
      'font_size': fontSize,
      'font_color': _toHexColor(fontColor),
      'margin': margin,
    };
  }
}

class StampStyle {
  final BorderConfig border;
  final FilterConfig filter;
  final TemplateConfig template;
  final List<TextOverlayConfig> textOverlays;
  final bool textEnabled;

  const StampStyle({
    this.border = const BorderConfig(),
    this.filter = const FilterConfig(),
    this.template = const TemplateConfig(),
    this.textOverlays = const [],
    this.textEnabled = true,
  });

  StampStyle copyWith({
    BorderConfig? border,
    FilterConfig? filter,
    TemplateConfig? template,
    List<TextOverlayConfig>? textOverlays,
    bool? textEnabled,
  }) {
    return StampStyle(
      border: border ?? this.border,
      filter: filter ?? this.filter,
      template: template ?? this.template,
      textOverlays: textOverlays ?? this.textOverlays,
      textEnabled: textEnabled ?? this.textEnabled,
    );
  }

  factory StampStyle.fromJson(Map<String, dynamic> json) {
    final textJson = json['text'] as Map<String, dynamic>? ?? {};
    final textItemsList = textJson['items'] as List? ?? [];
    return StampStyle(
      border: BorderConfig.fromJson(json['border'] as Map<String, dynamic>? ?? {}),
      filter: FilterConfig.fromJson(json['filter'] as Map<String, dynamic>? ?? {}),
      template: TemplateConfig.fromJson(json['template'] as Map<String, dynamic>? ?? {}),
      textOverlays: textItemsList.map((item) => TextOverlayConfig.fromJson(item as Map<String, dynamic>)).toList(),
      textEnabled: textJson['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'border': border.toJson(),
      'filter': filter.toJson(),
      'template': template.toJson(),
      'text': {
        'enabled': textEnabled,
        'items': textOverlays.map((e) => e.toJson()).toList(),
      }
    };
  }
}

// Helper methods for color conversion
Color _parseHexColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String _toHexColor(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
