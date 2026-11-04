/// A mod listed under an article (GET /api/mods/article/:slug).
///
/// Deliberately lenient: the backend's ModResponseDto omits fields it has no
/// value for, so everything except [id] is nullable and parsed tolerantly.
class GameMod {
  final int id;
  final String? name;
  final String? description;
  final String? version;
  final String? downloadLink;
  final String? status;
  final String? type;
  final String? language;
  final String? creditTo;
  final String? sha256;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  GameMod({
    required this.id,
    this.name,
    this.description,
    this.version,
    this.downloadLink,
    this.status,
    this.type,
    this.language,
    this.creditTo,
    this.sha256,
    this.fileSizeBytes,
    this.createdAt,
  });

  factory GameMod.fromJson(Map<String, dynamic> json) {
    return GameMod(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      version: json['version']?.toString(),
      downloadLink: json['downloadLink']?.toString(),
      status: json['status']?.toString(),
      type: json['type']?.toString(),
      language: json['language']?.toString(),
      creditTo: json['creditTo']?.toString(),
      sha256: json['sha256']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is num
          ? (json['fileSizeBytes'] as num).toInt()
          : int.tryParse('${json['fileSizeBytes']}'),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }
}

class GameModsResponse {
  final List<GameMod> mods;
  final int modsCount;

  GameModsResponse({required this.mods, required this.modsCount});

  factory GameModsResponse.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    final list = map['mods'];
    final mods = list is List
        ? list
              .whereType<Map<String, dynamic>>()
              .map(GameMod.fromJson)
              .toList()
        : <GameMod>[];
    return GameModsResponse(
      mods: mods,
      modsCount: (map['modsCount'] as num?)?.toInt() ?? mods.length,
    );
  }
}

/// A mod installed into a game directory. Persisted as `installed_mods.json`
/// next to the game, same shape ChanoX2 uses plus [backupId] for rollback.
class InstalledModRecord {
  final int id;
  final String name;
  final String version;
  final String installedAt;
  final String filename;
  final String backupId;

  InstalledModRecord({
    required this.id,
    required this.name,
    required this.version,
    required this.installedAt,
    required this.filename,
    required this.backupId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'installedAt': installedAt,
    'filename': filename,
    'backupId': backupId,
  };

  factory InstalledModRecord.fromJson(Map<String, dynamic> json) {
    return InstalledModRecord(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      installedAt: json['installedAt']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      backupId: json['backupId']?.toString() ?? '',
    );
  }
}
