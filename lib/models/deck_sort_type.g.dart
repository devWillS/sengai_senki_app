// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_sort_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeckSortTypeAdapter extends TypeAdapter<DeckSortType> {
  @override
  final int typeId = 1;

  @override
  DeckSortType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeckSortType.cardNumAsc;
      case 1:
        return DeckSortType.cardNumDesc;
      case 2:
        return DeckSortType.cardIdAsc;
      case 3:
        return DeckSortType.cardIdDesc;
      case 4:
        return DeckSortType.costAsc;
      case 5:
        return DeckSortType.costDesc;
      case 6:
        return DeckSortType.apAsc;
      case 7:
        return DeckSortType.apDesc;
      case 8:
        return DeckSortType.hpAsc;
      case 9:
        return DeckSortType.hpDesc;
      default:
        return DeckSortType.cardNumAsc;
    }
  }

  @override
  void write(BinaryWriter writer, DeckSortType obj) {
    switch (obj) {
      case DeckSortType.cardNumAsc:
        writer.writeByte(0);
        break;
      case DeckSortType.cardNumDesc:
        writer.writeByte(1);
        break;
      case DeckSortType.cardIdAsc:
        writer.writeByte(2);
        break;
      case DeckSortType.cardIdDesc:
        writer.writeByte(3);
        break;
      case DeckSortType.costAsc:
        writer.writeByte(4);
        break;
      case DeckSortType.costDesc:
        writer.writeByte(5);
        break;
      case DeckSortType.apAsc:
        writer.writeByte(6);
        break;
      case DeckSortType.apDesc:
        writer.writeByte(7);
        break;
      case DeckSortType.hpAsc:
        writer.writeByte(8);
        break;
      case DeckSortType.hpDesc:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckSortTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
