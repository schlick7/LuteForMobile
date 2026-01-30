// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageCacheEntryAdapter extends TypeAdapter<PageCacheEntry> {
  @override
  final typeId = 3;

  @override
  PageCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageCacheEntry(
      metadataHtml: fields[0] as String,
      pageTextHtml: fields[1] as String,
      timestamp: (fields[2] as num).toInt(),
      sizeInBytes: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PageCacheEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.metadataHtml)
      ..writeByte(1)
      ..write(obj.pageTextHtml)
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
      other is PageCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
