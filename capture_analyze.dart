import 'dart:io';

void main() {
  final result = Process.runSync('dart', [
    'analyze',
    'core',
    'skeleton',
    'action',
    'laravel_provider',
    'supabase_provider',
    '--format',
    'machine',
  ]);
  File(
    'final_analysis_clean.txt',
  ).writeAsStringSync(result.stdout + result.stderr);
  print('Done');
}
