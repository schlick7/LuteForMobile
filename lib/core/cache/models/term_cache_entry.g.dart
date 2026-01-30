// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'term_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TermCacheEntryAdapter extends TypeAdapter<TermCacheEntry> {
  @override
  final typeId = 5;

  @override
  TermCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TermCacheEntry(
      termId: (fields[0] as num).toInt(),
      text: fields[1] as String,
      translation: fields[2] as String?,
      statusId: (fields[3] as num).toInt(),
      statusText: fields[4] as String,
      languageId: (fields[5] as num).toInt(),
      languageName: fields[6] as String,
      parentText: fields[7] as String?,
      tags: fields[8] as String,
      createdAt: fields[9] as String,
      romanization: fields[10] as String?,
      source: fields[11] as String?,
      timestamp: (fields[12] as num).toInt(),
      sizeInBytes: (fields[13] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TermCacheEntry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.termId)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.translation)
      ..writeByte(3)
      ..write(obj.statusId)
      ..writeByte(4)
      ..write(obj.statusText)
      ..writeByte(5)
      ..write(obj.languageId)
      ..writeByte(6)
      ..write(obj.languageName)
      ..writeByte(7)
      ..write(obj.parentText)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.romanization)
      ..writeByte(11)
      ..write(obj.source)
      ..writeByte(12)
      ..write(obj.timestamp)
      ..writeByte(13)
      ..write(obj.sizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
