import 'dart:io';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';
import 'package:stampshunter/features/stamp/domain/repositories/stamp_repository.dart';
import 'package:stampshunter/features/stamp/data/datasources/stamp_remote_datasource.dart';

class StampRepositoryImpl implements StampRepository {
  final StampRemoteDataSource remoteDataSource;

  StampRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Stamp> createStamp({
    required File file,
    String? title,
    String? description,
    List<String>? tags,
    required bool isPublic,
    required StampStyle style,
  }) {
    return remoteDataSource.createStamp(
      file: file,
      title: title,
      description: description,
      tags: tags,
      isPublic: isPublic,
      style: style,
    );
  }

  @override
  Future<Stamp> getStamp(String stampId) {
    return remoteDataSource.getStamp(stampId);
  }
}
