
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
}
