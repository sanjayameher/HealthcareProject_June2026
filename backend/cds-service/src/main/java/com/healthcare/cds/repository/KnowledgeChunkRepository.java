package com.healthcare.cds.repository;

import com.healthcare.cds.dto.internal.ChunkMatch;
import lombok.RequiredArgsConstructor;
import org.postgresql.util.PGobject;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;

/**
 * pgvector similarity search uses raw JDBC rather than a JPA entity — Hibernate has
 * no built-in mapping for the Postgres `vector` type, and hand-rolling one adds more
 * risk than a plain JdbcTemplate query for what is otherwise a simple read/insert path.
 */
@Repository
@RequiredArgsConstructor
public class KnowledgeChunkRepository {

    private final JdbcTemplate jdbcTemplate;

    public boolean hasAnyChunks() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM dev.cds_knowledge_chunks", Integer.class);
        return count != null && count > 0;
    }

    public void insert(String sourceType, String sourceRef, String content, float[] embedding) {
        PGobject vector = toPgVector(embedding);
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO dev.cds_knowledge_chunks (source_type, source_ref, content, embedding) " +
                            "VALUES (?, ?, ?, ?)");
            ps.setString(1, sourceType);
            ps.setString(2, sourceRef);
            ps.setString(3, content);
            ps.setObject(4, vector);
            return ps;
        });
    }

    public List<ChunkMatch> similaritySearch(float[] queryEmbedding, int limit, double minSimilarity) {
        PGobject vector = toPgVector(queryEmbedding);
        String sql = """
                SELECT id, source_type, source_ref, content,
                       1 - (embedding <=> ?) AS similarity
                FROM dev.cds_knowledge_chunks
                WHERE 1 - (embedding <=> ?) > ?
                ORDER BY embedding <=> ?
                LIMIT ?
                """;
        return jdbcTemplate.query(sql,
                (rs, rowNum) -> new ChunkMatch(
                        UUID.fromString(rs.getString("id")),
                        rs.getString("source_type"),
                        rs.getString("source_ref"),
                        rs.getString("content"),
                        rs.getDouble("similarity")
                ),
                vector, vector, minSimilarity, vector, limit);
    }

    private PGobject toPgVector(float[] embedding) {
        StringBuilder sb = new StringBuilder(embedding.length * 8);
        sb.append('[');
        for (int i = 0; i < embedding.length; i++) {
            if (i > 0) sb.append(',');
            sb.append(embedding[i]);
        }
        sb.append(']');
        try {
            PGobject obj = new PGobject();
            obj.setType("vector");
            obj.setValue(sb.toString());
            return obj;
        } catch (SQLException e) {
            throw new IllegalStateException("Failed to encode embedding as pgvector literal", e);
        }
    }
}
