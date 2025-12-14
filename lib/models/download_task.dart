enum DownloadTaskStatus {
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
}

enum DownloadType {
  file,
  archive,
  folder,
}

class DownloadTask {
  final String url;
  final DownloadTaskStatus status;
  final double progress;
  final String? filePath;
  final String? fileName;
  final DownloadType type;
  final String? taskId; // ✨ เพิ่มฟิลด์นี้สำหรับ flutter_downloader
  final String? imageUrl;
  final String? version;
  final String? packageName; // Package name of installed app

  DownloadTask({
    required this.url,
    this.status = DownloadTaskStatus.enqueued,
    this.progress = 0.0,
    this.filePath,
    this.fileName,
    this.type = DownloadType.file,
    this.taskId, // ✨ เพิ่มใน constructor
    this.imageUrl,
    this.version,
    this.packageName,
  });

  DownloadTask copyWith({
    DownloadTaskStatus? status,
    double? progress,
    String? filePath,
    String? fileName,
    DownloadType? type,
    String? taskId,
    String? imageUrl,
    String? version,
    String? packageName,
  }) {
    return DownloadTask(
      url: url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      taskId: taskId ?? this.taskId,
      imageUrl: imageUrl ?? this.imageUrl,
      version: version ?? this.version,
      packageName: packageName ?? this.packageName,
    );
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      url: json['url'] as String,
      status: _statusFromName(json['status'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      type: _typeFromName(json['type'] as String?),
      taskId: json['taskId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      version: json['version'] as String?,
      packageName: json['packageName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'status': status.name,
      'progress': progress,
      'filePath': filePath,
      'fileName': fileName,
      'type': type.name,
      'taskId': taskId,
      'imageUrl': imageUrl,
      'version': version,
      'packageName': packageName,
    };
  }

  static DownloadTaskStatus _statusFromName(String? value) {
    if (value == null) {
      return DownloadTaskStatus.enqueued;
    }
    return DownloadTaskStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => DownloadTaskStatus.enqueued,
    );
  }

  static DownloadType _typeFromName(String? value) {
    if (value == null) {
      return DownloadType.file;
    }
    return DownloadType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => DownloadType.file,
    );
  }
}