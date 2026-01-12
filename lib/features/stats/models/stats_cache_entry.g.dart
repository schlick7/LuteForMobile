// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatsCacheEntryAdapter extends TypeAdapter<StatsCacheEntry> {
  @override
  final typeId = 1;

  @override
  StatsCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatsCacheEntry(
      stats: (fields[0] as Map).cast<String, LanguageReadingStats>(),
      timestamp: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StatsCacheEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.stats)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
