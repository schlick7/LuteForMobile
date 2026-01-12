import 'package:hive_ce/hive.dart';
import 'tooltip_cache_entry.dart';

class TooltipCacheEntryAdapter extends TypeAdapter<TooltipCacheEntry> {
  @override
  final int typeId = 0;

  @override
  TooltipCacheEntry read(BinaryReader reader) {
    return TooltipCacheEntry(
      wordId: reader.readInt(),
      tooltipHtml: reader.readString(),
      timestamp: reader.readInt(),
      sizeInBytes: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TooltipCacheEntry obj) {
    writer.writeInt(obj.wordId);
    writer.writeString(obj.tooltipHtml);
    writer.writeInt(obj.timestamp);
    writer.writeInt(obj.sizeInBytes);
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
