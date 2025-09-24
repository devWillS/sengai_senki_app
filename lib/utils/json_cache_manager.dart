import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class JsonCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'libCachedImageData';

  static final JsonCacheManager _instance = JsonCacheManager._();

  factory JsonCacheManager() {
    return _instance;
  }

  JsonCacheManager._()
      : super(
          Config(
            key,
            maxNrOfCacheObjects: 10000,
            repo: JsonCacheInfoRepository(),
          ),
        );
}
