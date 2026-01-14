// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SentenceCacheEntryAdapter extends TypeAdapter<SentenceCacheEntry> {
  @override
  final typeId = 4;

  @override
  SentenceCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SentenceCacheEntry(
      sentences: (fields[0] as List).cast<CustomSentence>(),
      timestamp: (fields[1] as num).toInt(),
      sizeInBytes: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SentenceCacheEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sentences)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.sizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SentenceCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
