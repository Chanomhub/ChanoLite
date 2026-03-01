import 'package:chanomhub_flutter/chanomhub_flutter.dart';

void main() {
  final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
  // This will fail to compile if getById doesn't exist.
  // We can't actually compile easily here without full setup, but let's try to assume it might.
  // Actually, I'll just check ArticleRepository and update the manual query first.
}
