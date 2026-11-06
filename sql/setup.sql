-- Run in the Supabase SQL Editor for your project.
-- Uses Cohere embed-english-v3.0, which returns 1024-dimensional vectors.
create extension if not exists vector with schema extensions;

create table if not exists public.documents (
    id bigserial primary key,
    content text,
    metadata jsonb,
    embedding extensions.vector(1024)
);

-- Do not grant broad public access to document contents.
alter table public.documents enable row level security;

-- Use a securely stored server-side Supabase secret/service-role key in n8n.
create or replace function public.match_documents (
    query_embedding extensions.vector(1024),
    match_count integer default 5,
    filter jsonb default '{}'::jsonb
)
returns table (
    id bigint,
    content text,
    metadata jsonb,
    similarity float
)
language plpgsql stable
as $$
begin
    return query
    select
        d.id,
        d.content,
        d.metadata,
        1 - (d.embedding <=> query_embedding) as similarity
    from public.documents as d
    where d.metadata @> filter
    order by d.embedding <=> query_embedding
    limit match_count;
end;
$$;

notify pgrst, 'reload schema';
