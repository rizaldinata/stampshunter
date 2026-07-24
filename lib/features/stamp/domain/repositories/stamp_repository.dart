import 'dart:io';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';

abstract class StampRepository {
  Future<Stamp> createStamp({
    required File file,
    String? title,
    String? description,
    List<String>? tags,
    required bool isPublic,
    required StampStyle style,
  });

  Future<Stamp> getStamp(String stampId);
}
