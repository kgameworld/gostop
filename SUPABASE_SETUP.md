# Supabase 소셜 로그인 설정 가이드

## 1. Supabase 프로젝트 생성

1. [Supabase](https://supabase.com)에 가입하고 새 프로젝트를 생성합니다.
2. 프로젝트가 생성되면 Settings > API에서 다음 정보를 확인합니다:
   - Project URL
   - anon public key

## 2. 환경 변수 설정

`lib/config/supabase_config.dart` 파일에서 실제 값으로 업데이트:

```dart
static const String supabaseUrl = 'YOUR_ACTUAL_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY';
```

## 3. 데이터베이스 스키마 설정

### 3.1 사용자 프로필 테이블 생성

Supabase SQL Editor에서 다음 SQL을 실행:

```sql
-- 사용자 프로필 테이블 생성
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  nickname TEXT,
  avatar_url TEXT,
  level INTEGER DEFAULT 1,
  total_games INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  is_guest BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 프로필만 읽고 수정할 수 있도록 정책 설정
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 프로필 업데이트 시 updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 3.2 게임 기록 테이블 생성

```sql
-- 게임 기록 테이블 생성
CREATE TABLE game_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  score INTEGER NOT NULL,
  is_win BOOLEAN NOT NULL,
  game_data JSONB NOT NULL,
  played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE game_history ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 게임 기록만 읽고 작성할 수 있도록 정책 설정
CREATE POLICY "Users can view own game history" ON game_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own game history" ON game_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX idx_game_history_user_id ON game_history(user_id);
CREATE INDEX idx_game_history_played_at ON game_history(played_at);
```

## 4. 소셜 로그인 설정

### 4.1 Google 로그인 설정

#### 4.1.1 Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com)에서 새 프로젝트 생성
2. Google+ API 활성화
3. OAuth 2.0 클라이언트 ID 생성
4. 승인된 리디렉션 URI에 다음 추가:
   - `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback`

#### 4.1.2 Supabase에서 Google Provider 설정

Supabase Dashboard > Authentication > Providers > Google에서:

1. Enable Google provider
2. Client ID와 Client Secret 입력
3. Save

### 4.2 Apple 로그인 설정

#### 4.2.1 Apple Developer Console 설정

1. [Apple Developer Console](https://developer.apple.com)에서 새 App ID 생성
2. Sign In with Apple 기능 활성화
3. Services ID 생성
4. Return URLs에 다음 추가:
   - `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback`

#### 4.2.2 Supabase에서 Apple Provider 설정

Supabase Dashboard > Authentication > Providers > Apple에서:

1. Enable Apple provider
2. Services ID, Team ID, Key ID, Private Key 입력
3. Save

### 4.3 Facebook 로그인 설정

#### 4.3.1 Facebook Developer Console 설정

1. [Facebook Developers](https://developers.facebook.com)에서 새 앱 생성
2. Facebook Login 제품 추가
3. OAuth 설정에서 Valid OAuth Redirect URIs에 다음 추가:
   - `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback`

#### 4.3.2 Supabase에서 Facebook Provider 설정

Supabase Dashboard > Authentication > Providers > Facebook에서:

1. Enable Facebook provider
2. Client ID와 Client Secret 입력
3. Save

## 5. 인증 설정

Supabase Dashboard > Authentication > Settings에서:

1. **Site URL**: 앱의 URL 설정
2. **Redirect URLs**: 다음 URL들을 추가:
   - `io.supabase.go-stop-app://login-callback/`

## 6. 플랫폼별 설정

### 6.1 iOS 설정

#### 6.1.1 Info.plist 설정

`ios/Runner/Info.plist`에 다음 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>io.supabase.go-stop-app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.go-stop-app</string>
    </array>
  </dict>
</array>
```

#### 6.1.2 Apple 로그인 설정

`ios/Runner/Info.plist`에 다음 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>signinwithapple</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>signinwithapple</string>
    </array>
  </dict>
</array>
```

#### 6.1.3 Facebook 로그인 설정

`ios/Runner/Info.plist`에 다음 추가:

```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>고스톱</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>facebook</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fbYOUR_FACEBOOK_APP_ID</string>
    </array>
  </dict>
</array>
```

### 6.2 Android 설정

#### 6.2.1 AndroidManifest.xml 설정

`android/app/src/main/AndroidManifest.xml`에 다음 추가:

```xml
<activity>
  <!-- 기존 activity 태그 내부에 추가 -->
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.go-stop-app" />
  </intent-filter>
</activity>
```

#### 6.2.2 Facebook 로그인 설정

`android/app/src/main/res/values/strings.xml`에 다음 추가:

```xml
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

## 7. 보안 설정

### 7.1 RLS 정책 확인

모든 테이블에 적절한 RLS 정책이 설정되어 있는지 확인:

```sql
-- 현재 RLS 정책 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';
```

### 7.2 API 키 보안

- `anon` 키는 공개적으로 사용 가능 (클라이언트에서 사용)
- `service_role` 키는 서버에서만 사용 (절대 클라이언트에 노출하지 않음)

## 8. 테스트

### 8.1 Google 로그인 테스트

1. 앱에서 Google 로그인 버튼 클릭
2. Google 계정 선택 및 권한 승인
3. Supabase Dashboard > Authentication > Users에서 사용자 확인
4. Database > Tables > profiles에서 프로필 데이터 확인

### 8.2 Apple 로그인 테스트

1. 앱에서 Apple 로그인 버튼 클릭
2. Apple ID로 로그인 및 권한 승인
3. Supabase Dashboard > Authentication > Users에서 사용자 확인
4. Database > Tables > profiles에서 프로필 데이터 확인

### 8.3 Facebook 로그인 테스트

1. 앱에서 Facebook 로그인 버튼 클릭
2. Facebook 계정으로 로그인 및 권한 승인
3. Supabase Dashboard > Authentication > Users에서 사용자 확인
4. Database > Tables > profiles에서 프로필 데이터 확인

### 8.4 게스트 로그인 테스트

1. 앱에서 게스트로 시작하기 버튼 클릭
2. 자동으로 게스트 계정 생성 확인
3. Database > Tables > profiles에서 is_guest 필드 확인

### 8.5 게임 기록 저장 테스트

1. 게임 플레이 후 기록 저장
2. Database > Tables > game_history에서 데이터 확인

## 9. 모니터링

Supabase Dashboard에서 다음 항목들을 모니터링:

- **Authentication > Users**: 사용자 관리
- **Database > Logs**: 데이터베이스 쿼리 로그
- **API > Logs**: API 호출 로그
- **Storage**: 파일 업로드 (아바타 이미지 등)

## 10. 배포 시 고려사항

1. **환경 변수**: 프로덕션 환경에서는 환경 변수로 관리
2. **도메인 설정**: 실제 도메인으로 Site URL 및 Redirect URLs 업데이트
3. **SSL 인증서**: HTTPS 필수
4. **백업**: 정기적인 데이터베이스 백업 설정

## 11. 문제 해결

### 11.1 Google 로그인 오류

- **"Invalid OAuth client"**: Google Cloud Console에서 클라이언트 ID 확인
- **"Redirect URI mismatch"**: 승인된 리디렉션 URI 확인
- **"Access blocked"**: Google Cloud Console에서 API 활성화 확인

### 11.2 Apple 로그인 오류

- **"Invalid Services ID"**: Apple Developer Console에서 Services ID 확인
- **"Invalid Key ID"**: Apple Developer Console에서 Key ID 확인
- **"Invalid Private Key"**: Private Key 형식 및 내용 확인

### 11.3 Facebook 로그인 오류

- **"Invalid App ID"**: Facebook Developer Console에서 App ID 확인
- **"Invalid Client Token"**: Facebook Developer Console에서 Client Token 확인
- **"OAuth Error"**: OAuth 설정 및 권한 확인

### 11.4 게스트 로그인 오류

- **"Signup disabled"**: Supabase에서 회원가입 활성화 확인
- **"Invalid email"**: 게스트 이메일 생성 로직 확인

### 11.5 일반적인 오류

- **"OAuth account not linked"**: 소셜 계정이 연결되지 않음
- **"Signup disabled"**: 회원가입이 비활성화됨
- **"Network error"**: 네트워크 연결 확인

## 12. 추가 설정

### 12.1 사용자 프로필 자동 생성

소셜 로그인 후 사용자 프로필을 자동으로 생성하려면 Supabase Functions를 사용할 수 있습니다:

```typescript
// supabase/functions/auth-callback/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  const { data: { user } } = await supabaseClient.auth.getUser()

  if (user) {
    // 프로필이 없으면 생성
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single()

    if (!profile) {
      await supabaseClient
        .from('profiles')
        .insert({
          id: user.id,
          email: user.email,
          nickname: user.user_metadata?.full_name || user.email?.split('@')[0] || 'User',
          level: 1,
          total_games: 0,
          wins: 0,
          is_guest: user.user_metadata?.is_guest || false,
        })
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

### 12.2 게스트 계정 관리

게스트 계정의 데이터 보존 기간을 설정하려면:

```sql
-- 게스트 계정 정리 함수 (30일 이상 된 게스트 계정 삭제)
CREATE OR REPLACE FUNCTION cleanup_guest_accounts()
RETURNS void AS $$
BEGIN
  DELETE FROM auth.users 
  WHERE user_metadata->>'is_guest' = 'true' 
    AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 매일 실행되는 스케줄러 (선택사항)
SELECT cron.schedule('cleanup-guest-accounts', '0 2 * * *', 'SELECT cleanup_guest_accounts();');
``` 