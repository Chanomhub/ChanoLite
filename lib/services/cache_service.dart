class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class CacheService {
  CacheService({this.maxEntries = 100});

  final int maxEntries;
  final Map<String, _CacheEntry> _cache = {};

  dynamic get(String key) {
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
    }
    
    return null;
  }

  void set(String key, dynamic data, {Duration duration = const Duration(minutes: 30)}) {
    _evictIfNeeded();
    final expiry = DateTime.now().add(duration);
    _cache[key] = _CacheEntry(data, expiry);
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void _evictIfNeeded() {
    if (_cache.length < maxEntries) return;

    // Remove expired entries first
    _cache.removeWhere((_, entry) => entry.isExpired);

    // If still over capacity, remove the first (oldest inserted) entry
    if (_cache.length >= maxEntries && _cache.isNotEmpty) {
      _cache.remove(_cache.keys.first);
    }
  }
}
