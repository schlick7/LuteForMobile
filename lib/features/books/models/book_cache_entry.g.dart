// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookCacheEntryAdapter extends TypeAdapter<BookCacheEntry> {
  @override
  final typeId = 2;

  @override
  BookCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookCacheEntry(
      activeBooks: (fields[0] as List).cast<Book>(),
      archivedBooks: (fields[1] as List).cast<Book>(),
      timestamp: (fields[2] as num).toInt(),
      cacheType: fields[3] == null ? 'full' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BookCacheEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.activeBooks)
      ..writeByte(1)
      ..write(obj.archivedBooks)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.cacheType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
