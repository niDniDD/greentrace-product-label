-- Supabase schema for product label and issue report

-- products table
create table if not exists products (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- batches table
create table if not exists batches (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid references products(id) on delete cascade,
  batch_number text not null unique,
  expiry_date date not null,
  composition jsonb not null,
  benefits text[] not null,
  instructions text[] not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- optional issue_types reference table
create table if not exists issue_types (
  value text primary key,
  label text not null
);

insert into issue_types (value, label) values
  ('Quality', 'Quality - คุณภาพ'),
  ('Label', 'Label - ฉลาก'),
  ('Safety', 'Safety - ความปลอดภัย')
on conflict do nothing;

-- issues table
create table if not exists issues (
  id uuid primary key default uuid_generate_v4(),
  batch_id uuid references batches(id) on delete cascade,
  issue_type text not null,
  description text not null,
  status text not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_issue_type check (issue_type in ('Quality', 'Label', 'Safety'))
);

-- sample view for API convenience
create view if not exists batch_label_view as
select
  b.id,
  b.batch_number,
  b.expiry_date,
  b.composition,
  b.benefits,
  b.instructions,
  b.created_at,
  b.updated_at,
  p.id as product_id,
  p.name as product_name,
  p.description as product_description
from batches b
join products p on p.id = b.product_id;
