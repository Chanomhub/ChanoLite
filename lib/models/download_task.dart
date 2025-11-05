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

  DownloadTask({
    required this.url,
    this.status = DownloadTaskStatus.enqueued,
    this.progress = 0.0,
    this.filePath,
    this.fileName,
    this.type = DownloadType.file,
    this.taskId, // ✨ เพิ่มใน constructor
  });

  DownloadTask copyWith({
    DownloadTaskStatus? status,
    double? progress,
    String? filePath,
    String? fileName,
    DownloadType? type,
    String? taskId, // ✨ เพิ่มใน copyWith
  }) {
    return DownloadTask(
      url: url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      taskId: taskId ?? this.taskId, // ✨ เพิ่มที่นี่
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
      taskId: json['taskId'] as String?, // ✨ เพิ่มการ deserialize
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
      'taskId': taskId, // ✨ เพิ่มการ serialize
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