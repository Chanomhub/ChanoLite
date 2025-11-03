class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class CacheService {
  final Map<String, _CacheEntry> _cache = {};

  dynamic get(String key) {
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      print('Cache HIT for key: $key');
      return entry.data;
    }
    
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
      print('Cache EXPIRED for key: $key');
    } else {
      print('Cache MISS for key: $key');
    }
    
    return null;
  }

  void set(String key, dynamic data, {Duration duration = const Duration(minutes: 30)}) {
    print('Caching data for key: $key for $duration');
    final expiry = DateTime.now().add(duration);
    _cache[key] = _CacheEntry(data, expiry);
  }
}
