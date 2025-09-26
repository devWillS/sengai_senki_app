// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeckModelAdapter extends TypeAdapter<DeckModel> {
  @override
  final int typeId = 0;

  @override
  DeckModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeckModel(
      name: fields[0] as String,
      description: fields[1] as String,
      mainDeckCards: (fields[2] as List).cast<String>(),
      magicDeckCards: (fields[3] as List).cast<String>(),
      sortType:
          fields[4] == null ? DeckSortType.costDesc : fields[4] as DeckSortType,
      groupCardColor: fields[5] == null ? false : fields[5] as bool,
      deckType: fields[6] == null ? DeckType.normal : fields[6] as DeckType,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DeckModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.mainDeckCards)
      ..writeByte(3)
      ..write(obj.magicDeckCards)
      ..writeByte(4)
      ..write(obj.sortType)
      ..writeByte(5)
      ..write(obj.groupCardColor)
      ..writeByte(6)
      ..write(obj.deckType)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
