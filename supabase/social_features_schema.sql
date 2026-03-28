create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint friendships_not_self check (requester_id <> addressee_id)
);

create unique index if not exists friendships_unique_pair_idx
on public.friendships (
  least(requester_id::text, addressee_id::text),
  greatest(requester_id::text, addressee_id::text)
);

create index if not exists friendships_requester_idx
on public.friendships (requester_id, updated_at desc);

create index if not exists friendships_addressee_idx
on public.friendships (addressee_id, updated_at desc);

drop trigger if exists friendships_set_updated_at on public.friendships;
create trigger friendships_set_updated_at
before update on public.friendships
for each row
execute function public.set_updated_at();

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(trim(content)) > 0),
  created_at timestamptz not null default timezone('utc', now()),
  constraint direct_messages_not_self check (sender_id <> recipient_id)
);

create index if not exists direct_messages_sender_idx
on public.direct_messages (sender_id, created_at desc);

create index if not exists direct_messages_recipient_idx
on public.direct_messages (recipient_id, created_at desc);

alter table public.friendships enable row level security;
alter table public.direct_messages enable row level security;

drop policy if exists "friendships_select_participants" on public.friendships;
create policy "friendships_select_participants"
on public.friendships
for select
using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friendships_insert_requester" on public.friendships;
create policy "friendships_insert_requester"
on public.friendships
for insert
with check (
  auth.uid() = requester_id
  and requester_id <> addressee_id
  and status = 'pending'
);

drop policy if exists "friendships_update_addressee" on public.friendships;
create policy "friendships_update_addressee"
on public.friendships
for update
using (auth.uid() = addressee_id or auth.uid() = requester_id)
with check (
  auth.uid() = addressee_id or auth.uid() = requester_id
);

drop policy if exists "friendships_delete_participants" on public.friendships;
create policy "friendships_delete_participants"
on public.friendships
for delete
using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "direct_messages_select_participants" on public.direct_messages;
create policy "direct_messages_select_participants"
on public.direct_messages
for select
using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "direct_messages_insert_sender" on public.direct_messages;
create policy "direct_messages_insert_sender"
on public.direct_messages
for insert
with check (
  auth.uid() = sender_id
  and sender_id <> recipient_id
);
