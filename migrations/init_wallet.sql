create table if not exists public.wallets (
  user_id uuid references auth.users on delete cascade primary key,
  balance bigint default 0 not null,
  updated_at timestamptz default now()
);

alter table public.wallets enable row level security;

create policy "Wallet owner can read/write"
  on public.wallets
  for all
  using (auth.uid() = user_id); 