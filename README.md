🚀 KRAFT: Media & Entertainment Society Platform

KRAFT는 미디어/엔터테인먼트 학회원들을 위한 올인원 플랫폼입니다.
단순한 LMS를 넘어, 각 부서(Department)의 아이덴티티를 시각적으로 보여주는 Dynamic Identity System과 창작물을 공유하는 Streaming/Archive 기능을 포함합니다.

🛠 Tech Stack

Framework: Flutter (Dart)

Backend: Supabase (PostgreSQL, Auth, Storage)

State Management: Riverpod

Routing: GoRouter

UI/Design: Google Fonts (Chakra Petch), Glassmorphism, Neon Theme

🎨 1. Identity & Departments (핵심 컨셉)

사용자가 소속된 부서에 따라 앱의 테마 컬러(Primary Color), 아이콘, 분위기가 즉시 변경됩니다.

Department

Role

Hex Color

Concept

BUSINESS

경영팀

0xFF00FF00 (Neon Green)

Data, Matrix, Strategy

A&R

A&R팀

0xFFD900FF (Neon Purple)

Trend, Vinyl, Insight

MUSIC

실음팀

0xFF00E5FF (Neon Cyan)

Waveform, Sound, Blue

DIRECTING

영상/디렉팅

0xFFFF3131 (Neon Red)

Rec, Glitch, Camera

📋 2. Functional Requirements (기능 명세)

A. Member (학회원)

Dynamic Onboarding: 로그인 시 부서 선택 -> 앱 전체 테마 변경.

Curriculum Dashboard: 주차별 커리큘럼(Week 1, Week 2...) 확인.

Assignment Submission: 과제(PDF, Link, Image) 업로드 및 제출.

Streaming (Mini Player): 학회원들이 올린 데모 음원 백그라운드 재생.

Attendance: QR 코드 스캔으로 출석 체크 (성공 시 햅틱 피드백).

B. Manager (임원진)

Curriculum Management: 앱 내에서 커리큘럼 추가/수정/삭제 (CRUD).

Assignment Approval: 제출된 과제 확인 후 Check 버튼으로 승인 (Approve).

Department Notice: 각 부서별 공지사항 작성 및 게시.

QR Generation: 출석 체크용 일회성 QR 코드 생성.

🗂 3. Flutter Project Structure (File Tree)

유지보수와 확장성을 고려하여 Feature-first Architecture로 설계되었습니다.

lib/
├── main.dart                      # [Entry] 앱 진입점, 초기화 로직
├── core/                          # [Core] 앱 전역에서 공통으로 쓰이는 설정
│   ├── constants/                 # - department_enum.dart (부서 정의), colors.dart
│   ├── router/                    # - app_router.dart (화면 이동 관리)
│   ├── state/                     # - global_providers.dart (현재 부서, 유저 정보)
│   └── utils/                     # - date_utils.dart, formatters.dart
├── theme/                         # [Design] 디자인 시스템
│   └── app_theme.dart             # - 부서별 동적 테마(ThemeData) 생성 로직
├── common/                        # [Common] 재사용 가능한 위젯 모음
│   ├── widgets/                   # - glass_card.dart (유리 질감 카드), buttons.dart
│   └── layout/                    # - main_shell.dart (Bottom Navigation 껍데기)
└── features/                      # [Features] 기능별 모듈 (가장 중요)
├── auth/                      # 1. 인증
│   ├── login_screen.dart      # - 로그인 및 부서 선택 화면
│   └── auth_provider.dart     # - 로그인 로직 핸들러
├── home/                      # 2. 메인 홈
│   ├── home_screen.dart       # - 대시보드 (공지사항 + 주차별 카드)
│   └── widgets/               # - dept_notice_card.dart
├── curriculum/                # 3. 커리큘럼 & 과제
│   ├── curriculum_list.dart   # - 주차별 리스트 화면
│   ├── assignment_upload.dart # - 과제 업로드 화면
│   └── curriculum_provider.dart # - 데이터 관리
├── streaming/                 # 4. 스트리밍
│   ├── mini_player.dart       # - 하단 고정 플레이어 UI
│   └── audio_service.dart     # - just_audio 재생 로직
└── admin/                     # 5. 관리자 기능
├── qr_create_screen.dart  # - QR 생성 화면
└── manager_provider.dart  # - 관리자 전용 로직


🗄 4. Supabase Database Schema (SQL)

Supabase 대시보드의 SQL Editor에 아래 코드를 복사/붙여넣기하고 실행(Run)하면 백엔드 준비가 완료됩니다.

-- [1] Teams Table (부서 정보 - 고정 데이터)
CREATE TABLE public.teams (
id SERIAL PRIMARY KEY,
name TEXT NOT NULL,         -- 'BUSINESS', 'A&R', ...
color_hex TEXT NOT NULL,    -- '0xFF00FF00'
asset_url TEXT              -- 배경 이미지 URL (옵션)
);

-- 초기 데이터 삽입 (필수)
INSERT INTO public.teams (name, color_hex) VALUES
('BUSINESS', '0xFF00FF00'),
('A&R', '0xFFD900FF'),
('MUSIC', '0xFF00E5FF'),
('DIRECTING', '0xFFFF3131');

-- [2] Users Table (사용자 정보)
CREATE TABLE public.users (
id UUID REFERENCES auth.users NOT NULL PRIMARY KEY, -- Supabase Auth ID와 연동
email TEXT,
name TEXT,
role TEXT DEFAULT 'member', -- 'manager' OR 'member'
team_id INTEGER REFERENCES public.teams(id),
created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- [3] Semesters (학기 정보)
CREATE TABLE public.semesters (
id SERIAL PRIMARY KEY,
name TEXT NOT NULL,         -- '2025-1'
is_active BOOLEAN DEFAULT false
);

-- [4] Curriculums (주차별 커리큘럼)
CREATE TABLE public.curriculums (
id SERIAL PRIMARY KEY,
semester_id INTEGER REFERENCES public.semesters(id),
week_number INTEGER NOT NULL, -- 1, 2, 3...
title TEXT NOT NULL,
description TEXT,
deadline TIMESTAMP WITH TIME ZONE,
created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- [5] Assignments (과제 제출)
CREATE TABLE public.assignments (
id SERIAL PRIMARY KEY,
curriculum_id INTEGER REFERENCES public.curriculums(id),
user_id UUID REFERENCES public.users(id),
content_url TEXT,           -- 파일 링크 or URL
status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
manager_feedback TEXT,
submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- [6] Attendances (출석 기록)
CREATE TABLE public.attendances (
id SERIAL PRIMARY KEY,
user_id UUID REFERENCES public.users(id),
week_number INTEGER NOT NULL,
check_in_time TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- (Option) RLS Policies: 개발 중에는 편의를 위해 모든 권한 허용
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read" ON public.teams FOR SELECT USING (true);
ALTER TABLE public.curriculums ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read" ON public.curriculums FOR SELECT USING (true);


🚀 5. Getting Started

Setup: flutter create kraft_app

Packages:

flutter pub add flutter_riverpod go_router supabase_flutter google_fonts flutter_animate just_audio url_launcher glass_kit qr_flutter mobile_scanner


Database: 위 SQL 코드를 Supabase에 실행.

Run: flutter run