-- Атлас: общие профили, партии и статистика. Выполнить целиком в SQL Editor.
-- Почта и пароли остаются внутри Supabase Auth, публичные таблицы их не содержат.
begin;
create table if not exists public.atlas_constellations (
 id text primary key, zodiac boolean not null, equator boolean not null, north boolean not null
);
insert into public.atlas_constellations (id,zodiac,equator,north) values
('And',false,false,true),
('Gem',true,false,true),
('UMa',false,false,true),
('CMa',false,false,false),
('Lib',true,false,false),
('Aqr',true,true,false),
('Aur',false,false,true),
('Lup',false,false,false),
('Boo',false,false,true),
('Com',false,false,true),
('Crv',false,false,false),
('Her',false,false,true),
('Hya',false,true,false),
('Col',false,false,false),
('CVn',false,false,true),
('Vir',true,true,false),
('Del',false,false,true),
('Dra',false,false,true),
('Mon',false,true,false),
('Ara',false,false,false),
('Pic',false,false,false),
('Cam',false,false,true),
('Gru',false,false,false),
('Lep',false,false,false),
('Oph',true,true,true),
('Ser',false,true,true),
('Dor',false,false,false),
('Ind',false,false,false),
('Cas',false,false,true),
('Car',false,false,false),
('Cet',false,true,false),
('Cap',true,false,false),
('Pyx',false,false,false),
('Pup',false,false,false),
('Cyg',false,false,true),
('Leo',true,true,true),
('Vol',false,false,false),
('Lyr',false,false,true),
('Vul',false,false,true),
('UMi',false,false,true),
('Equ',false,false,true),
('LMi',false,false,true),
('CMi',false,true,true),
('Mic',false,false,false),
('Mus',false,false,false),
('Ant',false,false,false),
('Nor',false,false,false),
('Ari',true,false,true),
('Oct',false,false,false),
('Ori',false,true,true),
('Aql',false,true,true),
('Pav',false,false,false),
('Vel',false,false,false),
('Peg',false,false,true),
('Per',false,false,true),
('For',false,false,false),
('Aps',false,false,false),
('Cnc',true,false,true),
('Cae',false,false,false),
('Psc',true,true,true),
('Lyn',false,false,true),
('CrB',false,false,true),
('Sex',false,true,false),
('Ret',false,false,false),
('Sco',true,false,false),
('Scl',false,false,false),
('Men',false,false,false),
('Sge',false,false,true),
('Sgr',true,false,false),
('Tel',false,false,false),
('Tau',true,true,true),
('Tri',false,false,true),
('Tuc',false,false,false),
('Phe',false,false,false),
('Cha',false,false,false),
('Cen',false,false,false),
('Cep',false,false,true),
('Cir',false,false,false),
('Hor',false,false,false),
('Crt',false,false,false),
('Sct',false,false,false),
('Eri',false,true,false),
('Hyi',false,false,false),
('CrA',false,false,false),
('PsA',false,false,false),
('Cru',false,false,false),
('TrA',false,false,false),
('Lac',false,false,true)
on conflict (id) do update set zodiac=excluded.zodiac,equator=excluded.equator,north=excluded.north;

create table if not exists public.atlas_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 nickname text not null check (char_length(nickname) between 1 and 24),
 created_at timestamptz not null default now()
);
create table if not exists public.atlas_games (
 id uuid primary key,
 player_id uuid not null references public.atlas_profiles(id),
 key text not null,
 score integer not null check (score>=0),
 accuracy integer not null check (accuracy between 0 and 100),
 seconds numeric not null check (seconds>=0),
 total integer not null,
 correct integer not null,
 answers jsonb not null,
 created_at timestamptz not null default now()
);
create index if not exists atlas_games_player_date on public.atlas_games(player_id,created_at desc);
create index if not exists atlas_games_board on public.atlas_games(key,score desc,accuracy desc,seconds,created_at);

alter table public.atlas_constellations enable row level security;
alter table public.atlas_profiles enable row level security;
alter table public.atlas_games enable row level security;
revoke all on public.atlas_constellations,public.atlas_profiles,public.atlas_games from public,anon,authenticated;
grant select on public.atlas_profiles,public.atlas_games to anon,authenticated;
drop policy if exists "Atlas public profiles" on public.atlas_profiles;
create policy "Atlas public profiles" on public.atlas_profiles for select to anon,authenticated using (true);
drop policy if exists "Atlas public games" on public.atlas_games;
create policy "Atlas public games" on public.atlas_games for select to anon,authenticated using (true);

create or replace function public.atlas_set_profile(p_nickname text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Нужно войти'; end if;
 if p_nickname is null or char_length(trim(p_nickname)) not between 1 and 24 then
  raise exception 'Ник: от 1 до 24 символов';
 end if;
 insert into public.atlas_profiles(id,nickname) values(auth.uid(),trim(p_nickname))
 on conflict(id) do update set nickname=excluded.nickname;
end;
$$;

create or replace function public.atlas_submit_game(
 p_id uuid,p_key text,p_seconds numeric,p_answers jsonb
) returns uuid language plpgsql security definer set search_path='' as $$
declare
 uid uuid:=auth.uid(); cat text; style text; kind text; amount integer;
 a jsonb; answer_id text; chosen_id text; n integer; wins integer:=0;
 cleaned jsonb:='[]'::jsonb; existing_owner uuid;
begin
 if uid is null then raise exception 'Нужно войти'; end if;
 if not exists(select 1 from public.atlas_profiles where id=uid) then raise exception 'Укажи ник'; end if;
 if p_id is null then raise exception 'Нет идентификатора партии'; end if;
 select player_id into existing_owner from public.atlas_games where id=p_id;
 if existing_owner is not null then
  if existing_owner<>uid then raise exception 'Чужая партия'; end if;
  return p_id;
 end if;
 if p_key is null or p_key !~ '^(zodiac|north|south|equator|ecliptic|all)\|(lines|dots)\|(timed|result)\|[0-9]+$' then
  raise exception 'Неверные настройки';
 end if;
 cat:=split_part(p_key,'|',1);style:=split_part(p_key,'|',2);kind:=split_part(p_key,'|',3);amount:=split_part(p_key,'|',4)::integer;
 if (kind='timed' and amount not in(30,60,120)) or (kind='result' and amount not in(10,20,30)) then raise exception 'Неверная длина игры'; end if;
 if p_seconds is null or p_seconds<0 or p_seconds>86400 then raise exception 'Неверное время'; end if;
 if kind='timed' and p_seconds<>amount then raise exception 'Неверная длительность'; end if;
 if p_answers is null or jsonb_typeof(p_answers)<>'array' then raise exception 'Неверные ответы'; end if;
 n:=jsonb_array_length(p_answers);
 if n>300 or (kind='result' and n<>amount) then raise exception 'Неверное число ответов'; end if;
 for a in select value from jsonb_array_elements(p_answers) loop
  answer_id:=a->>'id';chosen_id:=a->>'chosen';
  if jsonb_typeof(a)<>'object' or answer_id is null or chosen_id is null then raise exception 'Неверный ответ'; end if;
  if not exists(select 1 from public.atlas_constellations c where c.id=answer_id and
    (cat='all' or (cat in('zodiac','ecliptic') and c.zodiac) or (cat='equator' and c.equator)
      or (cat='north' and c.north) or (cat='south' and not c.north))) then raise exception 'Созвездие вне набора'; end if;
  if not exists(select 1 from public.atlas_constellations where id=chosen_id) then raise exception 'Неизвестный вариант'; end if;
  if answer_id=chosen_id then wins:=wins+1;end if;
  cleaned:=cleaned||jsonb_build_array(jsonb_build_object('id',answer_id,'chosen',chosen_id,'correct',answer_id=chosen_id));
 end loop;
 insert into public.atlas_games(id,player_id,key,score,accuracy,seconds,total,correct,answers)
 values(p_id,uid,p_key,wins*10,case when n=0 then 0 else round(wins*100.0/n)::integer end,p_seconds,n,wins,cleaned);
 return p_id;
end;
$$;

create or replace function public.atlas_leaderboard(p_key text)
returns table(id uuid,player_id uuid,nickname text,key text,score integer,accuracy integer,seconds numeric,created_at timestamptz)
language sql stable security invoker set search_path='' as $$
 select g.id,g.player_id,p.nickname,g.key,g.score,g.accuracy,g.seconds,g.created_at
 from public.atlas_games g join public.atlas_profiles p on p.id=g.player_id
 where g.key=p_key
 order by g.score desc,g.accuracy desc,case when split_part(p_key,'|',3)='result' then g.seconds else 0 end,g.created_at
 limit 20;
$$;
revoke all on function public.atlas_set_profile(text),public.atlas_submit_game(uuid,text,numeric,jsonb),public.atlas_leaderboard(text) from public,anon,authenticated;
grant execute on function public.atlas_set_profile(text),public.atlas_submit_game(uuid,text,numeric,jsonb) to authenticated;
grant execute on function public.atlas_leaderboard(text) to anon,authenticated;
commit;
