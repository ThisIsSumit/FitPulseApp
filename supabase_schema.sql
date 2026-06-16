-- ============================================================
-- FitPulse — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ── Enable UUID extension ────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── profiles ─────────────────────────────────────────────────
create table if not exists profiles (
  id                    uuid primary key references auth.users(id) on delete cascade,
  name                  text not null default '',
  email                 text not null default '',
  photo_url             text not null default '',
  bio                   text not null default '',
  followers             text[]   not null default '{}',
  following             text[]   not null default '{}',
  total_workouts        integer  not null default 0,
  total_calories_burned integer  not null default 0,
  streak                integer  not null default 0,
  level                 integer  not null default 1,
  xp                    integer  not null default 0,
  created_at            timestamptz not null default now()
);

-- auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', ''),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── workouts ──────────────────────────────────────────────────
create table if not exists workouts (
  id          uuid primary key default uuid_generate_v4(),
  name        text    not null,
  category    text    not null,
  difficulty  text    not null,
  duration    integer not null default 0,
  calories    integer not null default 0,
  image       text    not null default '',
  exercises   jsonb   not null default '[]',
  created_at  timestamptz not null default now()
);

-- ── workout_logs ──────────────────────────────────────────────
create table if not exists workout_logs (
  id              uuid primary key default uuid_generate_v4(),
  uid             uuid not null references profiles(id) on delete cascade,
  workout_id      uuid references workouts(id) on delete set null,
  workout_name    text    not null default '',
  duration        integer not null default 0,
  calories        integer not null default 0,
  exercises_count integer not null default 0,
  created_at      timestamptz not null default now()
);

-- ── nutrition_logs ─────────────────────────────────────────────
create table if not exists nutrition_logs (
  id         uuid primary key default uuid_generate_v4(),
  uid        uuid not null references profiles(id) on delete cascade,
  food_name  text    not null,
  meal_type  text    not null default 'Snack',
  calories   integer not null default 0,
  protein    numeric not null default 0,
  carbs      numeric not null default 0,
  fat        numeric not null default 0,
  created_at timestamptz not null default now()
);

-- ── posts ─────────────────────────────────────────────────────
create table if not exists posts (
  id             uuid primary key default uuid_generate_v4(),
  uid            uuid not null references profiles(id) on delete cascade,
  text           text    not null,
  image_url      text,
  type           text    not null default 'Achievement',
  likes          text[]  not null default '{}',
  comments_count integer not null default 0,
  user_info      jsonb   not null default '{}',
  created_at     timestamptz not null default now()
);

-- ── comments ──────────────────────────────────────────────────
create table if not exists comments (
  id         uuid primary key default uuid_generate_v4(),
  post_id    uuid not null references posts(id) on delete cascade,
  uid        uuid not null references profiles(id) on delete cascade,
  text       text not null,
  user_info  jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ── challenges ────────────────────────────────────────────────
create table if not exists challenges (
  id           uuid primary key default uuid_generate_v4(),
  title        text    not null,
  description  text    not null default '',
  icon         text    not null default '🏋',
  category     text    not null default '',
  duration     integer not null default 0,
  participants text[]  not null default '{}',
  target       integer not null default 0,
  unit         text    not null default '',
  reward       text    not null default '',
  start_date   timestamptz not null default now(),
  end_date     timestamptz not null default now()
);

-- ── Helper RPC: increment comments count ─────────────────────
create or replace function increment_comments(post_id uuid)
returns void language sql security definer as $$
  update posts set comments_count = comments_count + 1 where id = post_id;
$$;

-- ── Helper RPC: increment profile stats ──────────────────────
create or replace function increment_profile_stats(
  p_id       uuid,
  p_workouts integer default 0,
  p_calories integer default 0,
  p_xp       integer default 0
)
returns void language sql security definer as $$
  update profiles set
    total_workouts        = total_workouts        + p_workouts,
    total_calories_burned = total_calories_burned + p_calories,
    xp                    = xp                    + p_xp
  where id = p_id;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================

alter table profiles       enable row level security;
alter table workouts       enable row level security;
alter table workout_logs   enable row level security;
alter table nutrition_logs enable row level security;
alter table posts          enable row level security;
alter table comments       enable row level security;
alter table challenges     enable row level security;

-- profiles
create policy "Profiles are viewable by authenticated users"
  on profiles for select using (auth.role() = 'authenticated');
create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

-- workouts (read-only for users)
create policy "Workouts viewable by all authenticated"
  on workouts for select using (auth.role() = 'authenticated');
create policy "Service role can insert workouts"
  on workouts for insert with check (auth.role() = 'service_role');

-- workout_logs
create policy "Users see own workout logs"
  on workout_logs for select using (auth.uid() = uid);
create policy "Users can insert own workout logs"
  on workout_logs for insert with check (auth.uid() = uid);

-- nutrition_logs
create policy "Users see own nutrition logs"
  on nutrition_logs for select using (auth.uid() = uid);
create policy "Users can insert own nutrition logs"
  on nutrition_logs for insert with check (auth.uid() = uid);

-- posts
create policy "Posts viewable by authenticated"
  on posts for select using (auth.role() = 'authenticated');
create policy "Users can create posts"
  on posts for insert with check (auth.uid() = uid);
create policy "Anyone authenticated can update posts (likes)"
  on posts for update using (auth.role() = 'authenticated');
create policy "Users can delete own posts"
  on posts for delete using (auth.uid() = uid);

-- comments
create policy "Comments viewable by authenticated"
  on comments for select using (auth.role() = 'authenticated');
create policy "Users can add comments"
  on comments for insert with check (auth.uid() = uid);
create policy "Users can delete own comments"
  on comments for delete using (auth.uid() = uid);

-- challenges
create policy "Challenges viewable by authenticated"
  on challenges for select using (auth.role() = 'authenticated');
create policy "Authenticated users can join challenges (update participants)"
  on challenges for update using (auth.role() = 'authenticated');

-- ============================================================
-- Storage Buckets (run separately or via Dashboard)
-- ============================================================
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
-- insert into storage.buckets (id, name, public) values ('post-images', 'post-images', true);

-- Storage policies for avatars
-- create policy "Avatar images are publicly accessible"
--   on storage.objects for select using (bucket_id = 'avatars');
-- create policy "Users can upload own avatar"
--   on storage.objects for insert with check (
--     bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
-- create policy "Users can update own avatar"
--   on storage.objects for update using (
--     bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for post-images
-- create policy "Post images are publicly accessible"
--   on storage.objects for select using (bucket_id = 'post-images');
-- create policy "Authenticated users can upload post images"
--   on storage.objects for insert with check (
--     bucket_id = 'post-images' and auth.role() = 'authenticated');
