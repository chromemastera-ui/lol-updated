-- Run this ONCE in Supabase: SQL Editor -> New query -> paste -> Run.

create table if not exists public.docs (
  coll text not null,
  id text not null,
  data jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default clock_timestamp(),
  primary key (coll, id)
);
create index if not exists docs_updated_idx on public.docs (updated_at);

create or replace function public.docs_touch() returns trigger as $$
begin new.updated_at := clock_timestamp(); return new; end $$ language plpgsql;
drop trigger if exists docs_touch on public.docs;
create trigger docs_touch before insert or update on public.docs
  for each row execute function public.docs_touch();

alter table public.docs enable row level security;
grant all on public.docs to anon;
drop policy if exists "friends can use docs" on public.docs;
create policy "friends can use docs" on public.docs for all to anon using (true) with check (true);

-- public bucket for photos and videos
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 52428800) on conflict (id) do nothing;
drop policy if exists "media read" on storage.objects;
drop policy if exists "media add" on storage.objects;
drop policy if exists "media change" on storage.objects;
drop policy if exists "media remove" on storage.objects;
create policy "media read"   on storage.objects for select to anon using (bucket_id = 'media');
create policy "media add"    on storage.objects for insert to anon with check (bucket_id = 'media');
create policy "media change" on storage.objects for update to anon using (bucket_id = 'media');
create policy "media remove" on storage.objects for delete to anon using (bucket_id = 'media');
