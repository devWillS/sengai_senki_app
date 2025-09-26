// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeckTypeAdapter extends TypeAdapter<DeckType> {
  @override
  final int typeId = 9;

  @override
  DeckType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeckType.normal;
      case 1:
        return DeckType.draft;
      default:
        return DeckType.normal;
    }
  }

  @override
  void write(BinaryWriter writer, DeckType obj) {
    switch (obj) {
      case DeckType.normal:
        writer.writeByte(0);
        break;
      case DeckType.draft:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
