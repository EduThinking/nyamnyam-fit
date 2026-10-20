# 냠냠핏 배포 가이드

누구나 자기 이메일로 가입해서 쓰는 식단·운동 기록 앱이에요.

- 화면: `index.html`
- 서버 함수: `api/config.js`(설정 전달), `api/ai.js`(AI 분석)
- 데이터베이스 설계: `supabase.sql`

## 1. Supabase (무료 데이터베이스와 로그인)
1. https://supabase.com 에 가입하고 **New project**를 만들어요. Region은 Northeast Asia (Seoul)을 골라요.
2. 왼쪽 메뉴 **SQL Editor**를 열고, `supabase.sql` 내용을 전부 붙여 넣은 뒤 **Run**을 눌러요.
3. 같은 방법으로 `supabase-foods.sql`(음식 목록 공유)과 `supabase-rewards.sql`(출석 덤벨·덤벨 선물), `supabase-photos.sql`(채널 글 사진), `supabase-chat.sql`(전체 실시간 채팅)도 실행해요.
4. **Authentication → Sign In / Providers → Email**에서 **Confirm email을 꺼요**. 켜 두면 가입할 때마다 인증 메일이 가는데, 무료 메일 발송은 시간당 몇 통으로 제한돼서 가입이 막혀요.
4. **Project Settings → API**에서 아래 두 값을 복사해 두세요.
   - Project URL (`https://xxxx.supabase.co`)
   - anon public key (공개용 키라서 노출돼도 괜찮아요. 데이터는 보안 규칙이 지켜요.)

## 2. Vercel (웹사이트 주소)
1. 받은 `nyamnyam-fit.zip`의 압축을 풀어요. 그 안의 파일과 폴더(`index.html`, `api`, `vendor` 등)를 GitHub 새 저장소에 올려요. github.com → **New repository** → **uploading an existing file** → 끌어다 놓기 → **Commit changes**
   - Vercel 사이트에는 폴더를 직접 올리는 기능이 없어서 GitHub를 거쳐야 해요.
2. https://vercel.com 에 GitHub 계정으로 로그인 → **Add New → Project** → 방금 만든 저장소 옆 **Import**
3. Import 화면의 **Environment Variables**에 아래 값을 넣고 **Deploy**를 눌러요.
   - `SUPABASE_URL` = 1-4의 Project URL
   - `SUPABASE_ANON_KEY` = 1-4의 anon key
   - `ANTHROPIC_API_KEY` = https://console.anthropic.com 에서 만든 API 키 (선택 사항이에요. 없으면 AI 분석만 꺼지고 나머지 기능은 그대로 돼요.)
4. 배포가 끝나면 Supabase **Authentication → URL Configuration**의 Site URL에 Vercel 주소를 넣어요.

## 3. 사용
- 사용자에게 Vercel 주소만 보내면 돼요. 각자 이메일과 비밀번호로 가입해요.
- 휴대폰 브라우저 메뉴에서 **홈 화면에 추가**를 누르면 앱처럼 쓸 수 있어요.

## 알아둘 점
- AI 분석은 내 API 키로 결제돼요. 사용자가 많아지면 Anthropic 콘솔에서 월 사용 한도를 꼭 걸어 두세요.
- 비밀번호 찾기는 아직 없어요. 필요하면 Supabase 대시보드의 Authentication → Users에서 직접 재설정할 수 있어요.
