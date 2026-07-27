package com.healthcare.cds.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.healthcare.cds.config.CdsProperties;
import com.healthcare.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.List;
import java.util.Map;

/** Free-tier alternative LLM provider — Groq's OpenAI-compatible chat completions API. */
@Component
@RequiredArgsConstructor
@Slf4j
public class GroqClient {

    private static final String API_BASE = "https://api.groq.com/openai/v1";

    private final CdsProperties props;
    private final RestClient restClient = RestClient.create(API_BASE);

    public String complete(String systemPrompt, String userPrompt) {
        Map<String, Object> body = Map.of(
                "model", props.getGroq().getModel(),
                "max_tokens", props.getGroq().getMaxTokens(),
                "messages", List.of(
                        Map.of("role", "system", "content", systemPrompt),
                        Map.of("role", "user", "content", userPrompt)
                )
        );

        try {
            JsonNode response = restClient.post()
                    .uri("/chat/completions")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + props.getGroq().getApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);

            JsonNode text = response == null ? null
                    : response.path("choices").path(0).path("message").path("content");
            if (text == null || text.isMissingNode()) {
                throw new BusinessException("Groq API returned an empty response",
                        HttpStatus.BAD_GATEWAY, "LLM_EMPTY_RESPONSE");
            }
            return text.asText();
        } catch (RestClientException e) {
            log.error("Groq API call failed", e);
            throw new BusinessException("Clinical decision support service is temporarily unavailable",
                    HttpStatus.BAD_GATEWAY, "LLM_UNAVAILABLE");
        }
    }
}
