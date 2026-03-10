-- Optional: sync watchlist and risk settings per user (anon or email).
-- Enable when using Supabase Auth in the app.
create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  watchlist jsonb not null default '[]'::jsonb,
  risk_daily_loss_limit double precision default 0,
  risk_max_position_size integer default 10,
  updated_at timestamptz not null default now(),
  unique(user_id)
);

alter table public.user_settings enable row level security;

create policy "Users can read own settings"
  on public.user_settings for select
  using (auth.uid() = user_id);

create policy "Users can insert own settings"
  on public.user_settings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own settings"
  on public.user_settings for update
  using (auth.uid() = user_id);
