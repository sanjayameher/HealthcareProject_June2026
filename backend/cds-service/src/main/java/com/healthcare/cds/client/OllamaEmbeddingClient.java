package com.healthcare.cds.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.healthcare.cds.config.CdsProperties;
import com.healthcare.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class OllamaEmbeddingClient {

    private final CdsProperties props;

    public float[] embed(String text) {
        RestClient restClient = RestClient.create(props.getOllama().getUrl());
        try {
            Map<String, Object> body = Map.of(
                    "model", props.getOllama().getEmbeddingModel(),
                    "prompt", text
            );
            JsonNode response = restClient.post()
                    .uri("/api/embeddings")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);

            JsonNode arr = response == null ? null : response.path("embedding");
            if (arr == null || !arr.isArray() || arr.isEmpty()) {
                throw new BusinessException("Ollama returned an empty embedding",
                        HttpStatus.BAD_GATEWAY, "EMBEDDING_EMPTY_RESPONSE");
            }
            float[] result = new float[arr.size()];
            for (int i = 0; i < arr.size(); i++) {
                result[i] = (float) arr.get(i).asDouble();
            }
            return result;
        } catch (RestClientException e) {
            log.error("Ollama embedding call failed — is Ollama running locally with '{}' pulled?",
                    props.getOllama().getEmbeddingModel(), e);
            throw new BusinessException(
                    "Embedding service unavailable — ensure Ollama is running at " + props.getOllama().getUrl() +
                            " with the '" + props.getOllama().getEmbeddingModel() + "' model pulled",
                    HttpStatus.BAD_GATEWAY, "EMBEDDING_UNAVAILABLE");
        }
    }
}
