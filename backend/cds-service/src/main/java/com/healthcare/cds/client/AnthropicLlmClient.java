package com.healthcare.cds.client;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.models.messages.Base64ImageSource;
import com.anthropic.models.messages.Base64PdfSource;
import com.anthropic.models.messages.ContentBlockParam;
import com.anthropic.models.messages.DocumentBlockParam;
import com.anthropic.models.messages.ImageBlockParam;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.TextBlockParam;
import com.healthcare.cds.config.CdsProperties;
import com.healthcare.cds.dto.request.TestReportAttachmentDto;
import com.healthcare.common.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.List;

/** Alternative LLM provider — Anthropic's Claude, selectable alongside Groq. Supports reading attached test reports directly. */
@Component
@Slf4j
public class AnthropicLlmClient implements LlmClient {

    private final CdsProperties props;
    private final AnthropicClient client;

    public AnthropicLlmClient(CdsProperties props) {
        this.props = props;
        this.client = AnthropicOkHttpClient.builder()
                .apiKey(props.getAnthropic().getApiKey())
                .build();
    }

    @Override
    public boolean supportsAttachments() {
        return true;
    }

    @Override
    public String complete(String systemPrompt, String userPrompt) {
        return send(MessageCreateParams.builder()
                .model(props.getAnthropic().getModel())
                .maxTokens((long) props.getAnthropic().getMaxTokens())
                .system(systemPrompt)
                .addUserMessage(userPrompt)
                .build());
    }

    @Override
    public String completeWithAttachment(String systemPrompt, String userPrompt, TestReportAttachmentDto attachment) {
        ContentBlockParam attachmentBlock = "application/pdf".equalsIgnoreCase(attachment.mimeType())
                ? ContentBlockParam.ofDocument(DocumentBlockParam.builder()
                        .source(Base64PdfSource.builder().data(attachment.base64Data()).build())
                        .build())
                : ContentBlockParam.ofImage(ImageBlockParam.builder()
                        .source(Base64ImageSource.builder()
                                .mediaType(toImageMediaType(attachment.mimeType()))
                                .data(attachment.base64Data())
                                .build())
                        .build());

        return send(MessageCreateParams.builder()
                .model(props.getAnthropic().getModel())
                .maxTokens((long) props.getAnthropic().getMaxTokens())
                .system(systemPrompt)
                .addUserMessageOfBlockParams(List.of(
                        attachmentBlock,
                        ContentBlockParam.ofText(TextBlockParam.builder().text(userPrompt).build())
                ))
                .build());
    }

    private String send(MessageCreateParams params) {
        try {
            Message response = client.messages().create(params);
            return response.content().stream()
                    .flatMap(block -> block.text().stream())
                    .map(textBlock -> textBlock.text())
                    .findFirst()
                    .orElseThrow(() -> new BusinessException("Claude API returned an empty response",
                            HttpStatus.BAD_GATEWAY, "LLM_EMPTY_RESPONSE"));
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Claude API call failed", e);
            throw new BusinessException("Clinical decision support service is temporarily unavailable",
                    HttpStatus.BAD_GATEWAY, "LLM_UNAVAILABLE");
        }
    }

    private Base64ImageSource.MediaType toImageMediaType(String mimeType) {
        return switch (mimeType.toLowerCase()) {
            case "image/jpeg", "image/jpg" -> Base64ImageSource.MediaType.IMAGE_JPEG;
            case "image/png" -> Base64ImageSource.MediaType.IMAGE_PNG;
            case "image/gif" -> Base64ImageSource.MediaType.IMAGE_GIF;
            case "image/webp" -> Base64ImageSource.MediaType.IMAGE_WEBP;
            default -> throw new BusinessException("Unsupported image type: " + mimeType,
                    HttpStatus.BAD_REQUEST, "UNSUPPORTED_ATTACHMENT_TYPE");
        };
    }
}
