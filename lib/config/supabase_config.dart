class SupabaseConfig {
  // Supabase 프로젝트 설정 (직접 입력)
  static const String supabaseUrl = 'https://rjzxuujwafggxhcsdlkh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqenh1dWp3YWZnZ3hoY3NkbGtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNTY0NTIsImV4cCI6MjA2NzYzMjQ1Mn0.AcKLMMwwJio9UbzSAwbkq4hbT0UWGeZR5p2MtDN4Jqg';

  // 테이블 이름들
  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';
  static const String gameHistoryTable = 'game_history';

  // RLS 정책을 위한 스키마
  static const String publicSchema = 'public';
} 