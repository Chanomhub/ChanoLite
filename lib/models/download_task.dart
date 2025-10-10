
enum DownloadTaskStatus { enqueued, running, complete, failed, canceled, paused }

enum DownloadType { file, archive, folder }

class DownloadTask {
  final String url;
  final DownloadTaskStatus status;
  final double progress;
  final String? filePath;
  final String? fileName;
  final DownloadType type;

  DownloadTask({
    required this.url,
    this.status = DownloadTaskStatus.enqueued,
    this.progress = 0.0,
    this.filePath,
    this.fileName,
    this.type = DownloadType.file,
  });

  DownloadTask copyWith({
    DownloadTaskStatus? status,
    double? progress,
    String? filePath,
    String? fileName,
    DownloadType? type,
  }) {
    return DownloadTask(
      url: url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
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
