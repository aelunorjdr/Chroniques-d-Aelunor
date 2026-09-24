-- À exécuter dans Supabase > SQL Editor
create table if not exists public.aelunor_views (
  track_id text not null,
  pseudo text not null,
  count integer not null default 0,
  primary key (track_id, pseudo)
);

alter table public.aelunor_views enable row level security;

-- Les statistiques peuvent être lues par le site.
drop policy if exists "Public can read Aelunor views" on public.aelunor_views;
create policy "Public can read Aelunor views"
on public.aelunor_views
for select to anon
using (true);

-- Le site ne fait pas d'INSERT/UPDATE direct : seul le RPC ci-dessous modifie les compteurs.
revoke insert, update, delete on public.aelunor_views from anon, authenticated;
grant select on public.aelunor_views to anon;

drop function if exists public.increment_aelunor_view(text, text);
create or replace function public.increment_aelunor_view(p_track_id text, p_pseudo text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_track_id not in ('cyriac', 'ezechiel', 'tony', 'kerian') then
    raise exception 'track invalide';
  end if;
  if p_pseudo is null or length(trim(p_pseudo)) = 0 or length(p_pseudo) > 40 then
    raise exception 'pseudo invalide';
  end if;

  insert into public.aelunor_views(track_id, pseudo, count)
  values (p_track_id, trim(p_pseudo), 1)
  on conflict (track_id, pseudo)
  do update set count = public.aelunor_views.count + 1;
end;
$$;

grant execute on function public.increment_aelunor_view(text, text) to anon;
