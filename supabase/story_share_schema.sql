create extension if not exists pgcrypto;

create table if not exists public.story_share_events (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  shared_by uuid not null references public.profiles(id) on delete cascade,
  opened_by uuid references public.profiles(id) on delete set null,
  channel text not null default 'clipboard' check (channel in ('clipboard')),
  created_at timestamptz not null default timezone('utc', now()),
  opened_at timestamptz
);

create index if not exists story_share_events_post_idx
on public.story_share_events (post_id, created_at desc);

create index if not exists story_share_events_shared_by_idx
on public.story_share_events (shared_by, created_at desc);

alter table public.story_share_events enable row level security;

drop policy if exists "story_share_insert_sharer" on public.story_share_events;
create policy "story_share_insert_sharer"
on public.story_share_events
for insert
with check (auth.uid() = shared_by);

drop policy if exists "story_share_select_related" on public.story_share_events;
create policy "story_share_select_related"
on public.story_share_events
for select
using (
  auth.uid() = shared_by
  or auth.uid() = opened_by
  or exists (
    select 1
    from public.posts
    where posts.id = post_id
      and posts.user_id = auth.uid()
  )
);

create or replace function public.record_story_share_open(
  share_event_id uuid,
  opened_post_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.story_share_events
  set opened_at = timezone('utc', now()),
      opened_by = auth.uid()
  where id = share_event_id
    and post_id = opened_post_id
    and opened_at is null
    and auth.uid() is not null
    and auth.uid() <> shared_by;
end;
$$;

revoke all on function public.record_story_share_open(uuid, uuid) from public;
grant execute on function public.record_story_share_open(uuid, uuid) to authenticated;
