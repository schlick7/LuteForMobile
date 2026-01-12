// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tooltip_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TooltipCacheEntryAdapter extends TypeAdapter<TooltipCacheEntry> {
  @override
  final typeId = 0;

  @override
  TooltipCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TooltipCacheEntry(
      wordId: (fields[0] as num).toInt(),
      tooltipHtml: fields[1] as String,
      timestamp: (fields[2] as num).toInt(),
      sizeInBytes: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TooltipCacheEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.tooltipHtml)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.sizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TooltipCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
