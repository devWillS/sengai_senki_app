import 'dart:io';

import 'package:bordered_text/bordered_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/models/deck.dart';
import 'package:senkai_sengi/utils/card_manager.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:senkai_sengi/utils/pair.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';
import 'package:senkai_sengi/widgets/cost_curve_chart.dart';
import 'package:share_plus/share_plus.dart';

class DeckScreenshotScreen extends ConsumerStatefulWidget {
  DeckScreenshotScreen({super.key, required this.deck});

  final List<CardData> master = Master().cardList;
  final Deck? deck;

  @override
  ConsumerState<DeckScreenshotScreen> createState() => _DeckWidgetLandState();
}

class _DeckWidgetLandState extends ConsumerState<DeckScreenshotScreen>
    with TickerProviderStateMixin {
  late PageController controller = PageController(initialPage: 0);

  late List<CardData> cardList = CardManager().getCardList(
    widget.master,
    widget.deck?.mainDeck ?? [],
  );

  late List<CardData> magicList = CardManager().getCardList(
    widget.master,
    widget.deck?.magicDeck ?? [],
  );

  late List<Widget> pages = [];

  late List<ScreenshotController> screenshotControllers = [];

  late StateProvider<int> currentIndex = StateProvider(
    (ref) =>
        (controller.positions.isNotEmpty ? (controller.page ?? 0) : 0).round(),
  );

  @override
  void didChangeDependencies() {
    controller.addListener(() {
      ref
          .read(currentIndex.notifier)
          .update(
            (state) =>
                (controller.positions.isNotEmpty ? (controller.page ?? 0) : 0)
                    .round(),
          );
    });
    final pages = createPages();
    this.pages = pages.map((e) => e.first).toList();
    screenshotControllers = pages.map((e) => e.second).toList();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.of(context).pop();
      },
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 0.7,
              child: PageView.builder(
                itemCount: pages.length,
                controller: controller,
                itemBuilder: (context, index) {
                  return MediaQuery.withNoTextScaling(child: pages[index]);
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < pages.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:
                            ref.watch(currentIndex) == i ? 1 : 0.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                !kIsWeb
                    ? ElevatedButton(
                        child: const Icon(Icons.ios_share),
                        onPressed: () async {
                          share((controller.page ?? 0).round());
                        },
                      )
                    : Container(),
                !kIsWeb && Platform.isAndroid
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 20),
                          ElevatedButton(
                            child: const Icon(Icons.save_alt),
                            onPressed: () async {
                              _androidSaveScreenshot(
                                (controller.page ?? 0).round(),
                              );
                            },
                          ),
                        ],
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> currentVer() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  _showLoading(
    BuildContext context,
    Indicator indicator,
    bool showPathBackground,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      barrierColor: Colors.black.withValues(alpha:0.5),
      // 画面マスクの透明度
      pageBuilder:
          (
            BuildContext context,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return PopScope(
              canPop: false,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12.5),
                  height: 75,
                  width: 75,
                  child: LoadingIndicator(
                    indicatorType: Indicator.lineSpinFadeLoader,
                    strokeWidth: 4.0,
                    pathBackgroundColor: showPathBackground
                        ? Colors.black45
                        : null,
                  ),
                ),
              ),
            );
          },
    );
  }

  void _androidSaveScreenshot(int page) async {
    final ScreenshotController screenshotController =
        screenshotControllers[page];
    var status = await Permission.storage.request();
    if (status.isGranted) {
      if (!mounted) return;
      _showLoading(context, Indicator.ballScaleMultiple, true);
      final directory = Directory('/storage/emulated/0/Pictures');
      final imagePath =
          '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final image = await screenshotController.capture(pixelRatio: 7.0);
      if (image != null) {
        final file = File(imagePath);
        await file.writeAsBytes(image);
        if (!mounted) return;
        Navigator.of(context).pop();
        showCompleteDialog();
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("書き出し完了しました。"),
          actions: [
            CupertinoDialogAction(
              child: const Text("閉じる"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Pair<Widget, ScreenshotController> landPage(Color backgroundColor) {
    final screenshotController = ScreenshotController();
    return Pair(
      Container(
        color: Colors.transparent,
        margin: const EdgeInsets.all(20),
        child: RotatedBox(
          quarterTurns: 1,
          child: Screenshot(
            controller: screenshotController,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),

                    // color: Colors.grey,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          "assets/images/deck_image_background.png",
                        ),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          backgroundColor,
                          BlendMode.colorBurn,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        BorderedText(
                          strokeColor: Colors.black,
                          strokeWidth: 5,
                          child: Text(
                            widget.deck?.name ?? "",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCardGrid(cardList, 20),
                            const SizedBox(height: 1),
                            _buildCardGrid(magicList, 10),
                          ],
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: EdgeInsetsGeometry.all(5),
                                  child: CostCurveChart(deck: widget.deck),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: EdgeInsetsGeometry.symmetric(
                                    vertical: 5,
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      Master().typeList.length,
                                      (index) {
                                        final type = Master().typeList[index];
                                        final count =
                                            widget.deck?.typeCount(type) ?? 0;
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Text(
                                              type,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                            Text("$count"),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BorderedText(
                              strokeColor: Colors.black,
                              strokeWidth: 5,
                              child: Text(
                                "image created by 千戯ポケット",
                                style: GoogleFonts.yujiBoku(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            FutureBuilder(
                              future: currentVer(),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<String> snapshot,
                                  ) {
                                    final platform = kIsWeb
                                        ? "w"
                                        : Platform.isAndroid
                                        ? "a"
                                        : "i";
                                    return BorderedText(
                                      strokeColor: Colors.black,
                                      strokeWidth: 5,
                                      child: Text(
                                        "v${snapshot.data ?? ""}($platform)",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      screenshotController,
    );
  }

  //
  // Pair<Widget, ScreenshotController> portraitPage({bool colored = false}) {
  //   final character = CardManager().characterCount(cardList);
  //   final event = CardManager().eventCount(cardList);
  //   final disguise = CardManager().disguiseCount(cardList);
  //   final hirameki = CardManager().hiramekiCount(cardList);
  //   final cutIn = CardManager().cutInCount(cardList);
  //
  //   final caseCard = Master().cardList.firstWhereOrNull(
  //     (card) => card.cardNum == widget.deck.caseCardNum,
  //   );
  //   List<Color> colors = [const Color(0xFF2F1C06), const Color(0xFF2F1C06)];
  //   if (caseCard != null && colored) {
  //     colors = caseCard.getColors();
  //   }
  //   final screenshotController = ScreenshotController();
  //
  //   return Pair(
  //     Center(
  //       child: AspectRatio(
  //         aspectRatio: 1,
  //         child: Container(
  //           color: Colors.transparent,
  //           margin: const EdgeInsets.all(20),
  //           child: Screenshot(
  //             controller: screenshotController,
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(10),
  //               child: Stack(
  //                 alignment: AlignmentDirectional.center,
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(15),
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         begin: FractionalOffset.topLeft,
  //                         end: FractionalOffset.bottomRight,
  //                         colors: colors,
  //                         stops: List.generate(colors.length, (index) {
  //                           if (colors.length == 2) {
  //                             return (index * 1 / 3) + 1 / 3;
  //                           }
  //                           return index / (colors.length - 1);
  //                         }),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(
  //                     width: double.maxFinite,
  //                     height: double.maxFinite,
  //                     child: ShaderMask(
  //                       shaderCallback: (Rect bounds) {
  //                         return LinearGradient(
  //                           colors: List.generate(colors.length, (index) {
  //                             if (!(caseCard != null && colored)) {
  //                               return Colors.white;
  //                             }
  //                             final letter = caseCard.color.length == 1
  //                                 ? caseCard.color
  //                                 : caseCard.color.characters.toList()[index];
  //                             return letter == "白" && colored
  //                                 ? Colors.black
  //                                 : Colors.white;
  //                           }),
  //                           begin: Alignment.topLeft,
  //                           end: Alignment.bottomRight,
  //                           stops: List.generate(colors.length, (index) {
  //                             if (colors.length == 2) {
  //                               return (index * 1 / 3) + 1 / 3;
  //                             }
  //                             return index / (colors.length - 1);
  //                           }),
  //                         ).createShader(bounds);
  //                       },
  //                       blendMode: BlendMode.srcIn, // フィルターのブレンドモードを設定
  //                       child: Image.asset(
  //                         'assets/images/white_bg.png',
  //                         fit: BoxFit.cover,
  //                       ),
  //                     ),
  //                   ),
  //                   Container(
  //                     padding: const EdgeInsets.all(15),
  //                     child: Column(
  //                       children: [
  //                         Expanded(
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                             children: [
  //                               Expanded(
  //                                 flex: 13,
  //                                 child: Row(
  //                                   mainAxisSize: MainAxisSize.min,
  //                                   mainAxisAlignment:
  //                                       MainAxisAlignment.spaceBetween,
  //                                   children: [
  //                                     DeckPartner(
  //                                       partnerNum: widget.deck.partnerNum,
  //                                     ),
  //                                     Expanded(
  //                                       child: Padding(
  //                                         padding: const EdgeInsets.only(
  //                                           left: 15,
  //                                         ),
  //                                         child: Column(
  //                                           mainAxisSize: MainAxisSize.min,
  //                                           children: [
  //                                             NoScalingText(
  //                                               widget.deck.name ?? "",
  //                                               style: TextStyle(
  //                                                 fontSize: 24,
  //                                                 fontWeight: FontWeight.w800,
  //                                                 color:
  //                                                     (caseCard?.color ?? "") ==
  //                                                             "白" &&
  //                                                         colored
  //                                                     ? Colors.black
  //                                                     : Colors.white,
  //                                               ),
  //                                               maxLines: 1,
  //                                               overflow: TextOverflow.ellipsis,
  //                                             ),
  //                                             Expanded(
  //                                               child: Row(
  //                                                 mainAxisAlignment:
  //                                                     MainAxisAlignment
  //                                                         .spaceAround,
  //                                                 children: [
  //                                                   DeckCase(
  //                                                     caseCardNum: widget
  //                                                         .deck
  //                                                         .caseCardNum,
  //                                                   ),
  //                                                   ClipRRect(
  //                                                     borderRadius:
  //                                                         const BorderRadius.all(
  //                                                           Radius.circular(5),
  //                                                         ),
  //                                                     child: AspectRatio(
  //                                                       aspectRatio: 1.4,
  //                                                       child: LevelCurve(
  //                                                         cardList: cardList,
  //                                                         type: ChartType.small,
  //                                                       ),
  //                                                     ),
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 10),
  //                               Expanded(
  //                                 flex: 28,
  //                                 child: Column(
  //                                   children: [
  //                                     Expanded(
  //                                       child: Center(
  //                                         child: LayoutBuilder(
  //                                           builder: (context, constraints) {
  //                                             return SizedBox(
  //                                               height: constraints.maxHeight,
  //                                               width:
  //                                                   constraints.maxHeight /
  //                                                   400 *
  //                                                   716,
  //                                               child: GridView.count(
  //                                                 shrinkWrap: true,
  //                                                 physics:
  //                                                     const NeverScrollableScrollPhysics(),
  //                                                 mainAxisSpacing: 1.0,
  //                                                 crossAxisSpacing: 1.0,
  //                                                 childAspectRatio: 0.716,
  //                                                 crossAxisCount: ref
  //                                                     .watch(deckType)
  //                                                     .crossAxisCount,
  //                                                 children: List.generate(
  //                                                   ref.watch(deckType).max,
  //                                                   (index) {
  //                                                     if (widget
  //                                                             .deck
  //                                                             .cardNumList
  //                                                             .length >
  //                                                         index) {
  //                                                       final cardNum = widget
  //                                                           .deck
  //                                                           .cardNumList[index];
  //                                                       return CardWidget(
  //                                                         card: widget.master
  //                                                             .firstWhere(
  //                                                               (element) =>
  //                                                                   element
  //                                                                       .cardNum ==
  //                                                                   cardNum,
  //                                                             ),
  //                                                       );
  //                                                     }
  //                                                     return AspectRatio(
  //                                                       aspectRatio: 0.716,
  //                                                       child: Container(
  //                                                         decoration: BoxDecoration(
  //                                                           color: Colors.white,
  //                                                           borderRadius:
  //                                                               BorderRadius.circular(
  //                                                                 3,
  //                                                               ),
  //                                                         ),
  //                                                         child: const Center(
  //                                                           child: NoScalingText(
  //                                                             "キャラ\nイベント",
  //                                                             textAlign:
  //                                                                 TextAlign
  //                                                                     .center,
  //                                                             style: TextStyle(
  //                                                               color:
  //                                                                   Colors.grey,
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .w900,
  //                                                               fontSize: 6,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                       ),
  //                                                     );
  //                                                   },
  //                                                 ),
  //                                               ),
  //                                             );
  //                                           },
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 10),
  //                                     SizedBox(
  //                                       height: 20,
  //                                       child: Row(
  //                                         mainAxisSize: MainAxisSize.min,
  //                                         children: [
  //                                           Row(
  //                                             children: [
  //                                               SvgPicture.asset(
  //                                                 "assets/icons/character.svg",
  //                                                 width: 20,
  //                                               ),
  //                                               NoScalingText(
  //                                                 "$character",
  //                                                 style: TextStyle(
  //                                                   color:
  //                                                       (caseCard?.color ?? "")
  //                                                               .endsWith(
  //                                                                 "白",
  //                                                               ) &&
  //                                                           colored
  //                                                       ? Colors.black
  //                                                       : Colors.white,
  //                                                   fontWeight: FontWeight.w900,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                           const SizedBox(width: 5),
  //                                           Row(
  //                                             children: [
  //                                               SvgPicture.asset(
  //                                                 "assets/icons/event.svg",
  //                                                 width: 20,
  //                                               ),
  //                                               NoScalingText(
  //                                                 "$event",
  //                                                 style: TextStyle(
  //                                                   color:
  //                                                       (caseCard?.color ?? "")
  //                                                               .endsWith(
  //                                                                 "白",
  //                                                               ) &&
  //                                                           colored
  //                                                       ? Colors.black
  //                                                       : Colors.white,
  //                                                   fontWeight: FontWeight.w900,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                           const SizedBox(width: 5),
  //                                           Row(
  //                                             children: [
  //                                               SvgPicture.asset(
  //                                                 "assets/icons/disguise.svg",
  //                                                 width: 20,
  //                                               ),
  //                                               NoScalingText(
  //                                                 "$disguise",
  //                                                 style: TextStyle(
  //                                                   color:
  //                                                       (caseCard?.color ?? "")
  //                                                               .endsWith(
  //                                                                 "白",
  //                                                               ) &&
  //                                                           colored
  //                                                       ? Colors.black
  //                                                       : Colors.white,
  //                                                   fontWeight: FontWeight.w900,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                           const SizedBox(width: 5),
  //                                           Row(
  //                                             children: [
  //                                               SvgPicture.asset(
  //                                                 "assets/icons/hirameki.svg",
  //                                                 width: 20,
  //                                               ),
  //                                               NoScalingText(
  //                                                 "$hirameki",
  //                                                 style: TextStyle(
  //                                                   color:
  //                                                       (caseCard?.color ?? "")
  //                                                               .endsWith(
  //                                                                 "白",
  //                                                               ) &&
  //                                                           colored
  //                                                       ? Colors.black
  //                                                       : Colors.white,
  //                                                   fontWeight: FontWeight.w900,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                           const SizedBox(width: 5),
  //                                           Row(
  //                                             children: [
  //                                               SvgPicture.asset(
  //                                                 "assets/icons/cut_in.svg",
  //                                                 width: 20,
  //                                               ),
  //                                               NoScalingText(
  //                                                 "$cutIn",
  //                                                 style: TextStyle(
  //                                                   color:
  //                                                       (caseCard?.color ?? "")
  //                                                               .endsWith(
  //                                                                 "白",
  //                                                               ) &&
  //                                                           colored
  //                                                       ? Colors.black
  //                                                       : Colors.white,
  //                                                   fontWeight: FontWeight.w900,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         FutureBuilder(
  //                           future: currentVer(),
  //                           builder:
  //                               (
  //                                 BuildContext context,
  //                                 AsyncSnapshot<String> snapshot,
  //                               ) {
  //                                 final platform = kIsWeb
  //                                     ? "w"
  //                                     : Platform.isAndroid
  //                                     ? "a"
  //                                     : "i";
  //                                 return NoScalingText(
  //                                   "v${snapshot.data ?? ""}($platform)",
  //                                   style: TextStyle(
  //                                     color:
  //                                         (caseCard?.color ?? "").endsWith(
  //                                               "白",
  //                                             ) &&
  //                                             colored
  //                                         ? Colors.black
  //                                         : Colors.white,
  //                                     fontSize: 10,
  //                                     fontWeight: FontWeight.w800,
  //                                   ),
  //                                 );
  //                               },
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     screenshotController,
  //   );
  // }

  void share(int page) async {
    final ScreenshotController screenshotController =
        screenshotControllers[page];
    if (!mounted) return;
    _showLoading(context, Indicator.ballScaleMultiple, true);
    final image = await screenshotController.capture(pixelRatio: 7.0);
    if (image == null) {
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/image.png').create();
    await imagePath.writeAsBytes(image);

    /// Share Plugin
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath.path, mimeType: "image/png")],
        fileNameOverrides: ['image.png'],
      ),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (result.status == ShareResultStatus.success) {
      showCompleteDialog();
    }
  }

  List<Pair<Widget, ScreenshotController>> createPages() {
    final result = <Pair<Widget, ScreenshotController>>[];
    result.add(landPage(Colors.red));
    result.add(landPage(Colors.blue));
    result.add(landPage(Colors.green));
    // result.add(landPage(colored: true));
    // result.add(portraitPage());
    // result.add(portraitPage(colored: true));
    return result;
  }

  Widget _buildCardGrid(List<CardData> cards, int totalSlots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 670 / 950,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < cards.length) {
          final card = cards[index];

          return Hero(
            tag: 'deck-${card.id}-$index',
            child: CardTile(card: card),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white70,
          ),
        );
      },
    );
  }
}
