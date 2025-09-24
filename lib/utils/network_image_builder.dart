import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/json_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class NetworkImageBuilder extends StatelessWidget {
  const NetworkImageBuilder(this.url, {super.key, this.aspectratio = 0.716});

  final String url;
  final double aspectratio;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      cacheManager: JsonCacheManager(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: const Duration(milliseconds: 100),
      imageUrl: url,
      filterQuality: FilterQuality.high,
      errorWidget: (context, url, error) => const Icon(Icons.error),
      placeholder: (context, url) {
        return Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white70,
          child: AspectRatio(
            aspectRatio: aspectratio,
            child: Container(color: Colors.white),
          ),
        );
      },
    );
  }
}
