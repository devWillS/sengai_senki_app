import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/models/deck.dart';

class CardManager {
  List<CardData> getCardList(
    List<CardData> master,
    List<DeckCardEntry> cardIdList,
  ) {
    final result = <CardData>[];
    for (var cardId in cardIdList) {
      try {
        final card = master.where((element) => element.id == cardId.cardId);
        int i = 0;
        while (i < cardId.count) {
          result.add(card.first);
          i++;
        }
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  // sort(
  //   List<CardInfo> list,
  //   DeckSortType type, {
  //   bool groupCardColor = false,
  //   String? partnerColor,
  // }) {
  //   if (groupCardColor) {
  //     switch (type) {
  //       case DeckSortType.cardNumAsc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.cardNumDesc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           return b.cardNum.compareTo(a.cardNum);
  //         });
  //       case DeckSortType.cardIdAsc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = a.cardId.compareTo(b.cardId);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.cardIdDesc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = b.cardId.compareTo(a.cardId);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.costAsc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (a.cost ?? 0).compareTo(b.cost ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.costDesc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (b.cost ?? 0).compareTo(a.cost ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.apAsc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (a.ap ?? 0).compareTo(b.ap ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.apDesc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (b.ap ?? 0).compareTo(a.ap ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.lpAsc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (a.lp ?? 0).compareTo(b.lp ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.lpDesc:
  //         list.sort((a, b) {
  //           int result = _comparePartnerColor(
  //             a,
  //             b,
  //             groupCardColor: groupCardColor,
  //             partnerColor: partnerColor,
  //           );
  //           if (result != 0) return result;
  //           int result2 = (b.lp ?? 0).compareTo(a.lp ?? 0);
  //           if (result2 != 0) return result2;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //     }
  //   } else {
  //     switch (type) {
  //       case DeckSortType.cardNumAsc:
  //         list.sort((a, b) => a.cardNum.compareTo(b.cardNum));
  //       case DeckSortType.cardNumDesc:
  //         list.sort((a, b) => b.cardNum.compareTo(a.cardNum));
  //       case DeckSortType.cardIdAsc:
  //         list.sort((a, b) {
  //           int result = a.cardId.compareTo(b.cardId);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.cardIdDesc:
  //         list.sort((a, b) {
  //           int result = b.cardId.compareTo(a.cardId);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.costAsc:
  //         list.sort((a, b) {
  //           int result = (a.cost ?? 0).compareTo(b.cost ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.costDesc:
  //         list.sort((a, b) {
  //           int result = (b.cost ?? 0).compareTo(a.cost ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.apAsc:
  //         list.sort((a, b) {
  //           int result = (a.ap ?? 0).compareTo(b.ap ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.apDesc:
  //         list.sort((a, b) {
  //           int result = (b.ap ?? 0).compareTo(a.ap ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.lpAsc:
  //         list.sort((a, b) {
  //           int result = (a.lp ?? 0).compareTo(b.lp ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //       case DeckSortType.lpDesc:
  //         list.sort((a, b) {
  //           int result = (b.lp ?? 0).compareTo(a.lp ?? 0);
  //           if (result != 0) return result;
  //           return a.cardNum.compareTo(b.cardNum);
  //         });
  //     }
  //   }
  // }
  //
  // CardInfo? get(String? cardNum) {
  //   return Master().cardList.firstWhereOrNull(
  //     (card) => card.cardNum == cardNum,
  //   );
  // }
  //
  // int _comparePartnerColor(
  //   CardInfo a,
  //   CardInfo b, {
  //   bool groupCardColor = false,
  //   String? partnerColor,
  // }) {
  //   if (a.color == partnerColor && b.color != partnerColor) return -1;
  //   if (b.color == partnerColor && a.color != partnerColor) return 1;
  //   return Master().color
  //       .indexOf(a.color)
  //       .compareTo(Master().color.indexOf(b.color));
  // }
  //
  // String getColorKey(String? cardNum) {
  //   final card = get(cardNum);
  //   if (cardNum == null) {
  //     return "";
  //   }
  //   switch (card!.color) {
  //     case "青":
  //       return "B";
  //     case "緑":
  //       return "G";
  //     case "白":
  //       return "W";
  //     case "赤":
  //       return "R";
  //     case "黄":
  //       return "Y";
  //     case "黒":
  //       return "K";
  //     default:
  //       return "";
  //   }
  // }
}
