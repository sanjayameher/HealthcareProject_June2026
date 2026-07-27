-- The ivfflat index is only useful once a table has enough rows to form
-- meaningful clusters (thousands+). On a small knowledge base like this one
-- (tens to low hundreds of rows), it returns zero rows via ORDER BY — a known
-- pgvector footgun. Sequential scan of <=> is effectively instant at this
-- scale, so no index is needed at all.
DROP INDEX IF EXISTS dev.cds_knowledge_chunks_embedding_idx;
