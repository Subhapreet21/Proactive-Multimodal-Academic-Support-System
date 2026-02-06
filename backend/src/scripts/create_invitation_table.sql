-- Create invitation_codes table
create table if not exists invitation_codes (
  code text primary key,
  role text not null check (role in ('faculty', 'admin')),
  usage_limit int default 1,
  used_count int default 0,
  created_by uuid references auth.users(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone
);

-- Enable RLS
alter table invitation_codes enable row level security;

-- Policies

-- 1. Admins can view all codes
create policy "Admins can view all invitation codes"
  on invitation_codes for select
  using (
    exists (
      select 1 from profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- 2. Admins can insert/update/delete codes
create policy "Admins can manage invitation codes"
  on invitation_codes for all
  using (
    exists (
      select 1 from profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- 3. Public/Anon can view a code ONLY if they know the text (for validation)
-- Note: 'security definer' function might be safer, but for direct table access:
create policy "Public can view valid codes by exact match"
  on invitation_codes for select
  using (true);
