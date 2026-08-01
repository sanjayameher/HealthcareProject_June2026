package com.healthcare.cds.client;

import com.healthcare.cds.dto.request.TestReportAttachmentDto;

/** A chat-completion capable LLM provider — one system prompt in, one text response out. */
public interface LlmClient {

    String complete(String systemPrompt, String userPrompt);

    /** Whether this provider can read an attached test report (image/document) directly. */
    default boolean supportsAttachments() {
        return false;
    }

    /** Only called when {@link #supportsAttachments()} is true. */
    default String completeWithAttachment(String systemPrompt, String userPrompt, TestReportAttachmentDto attachment) {
        throw new UnsupportedOperationException(getClass().getSimpleName() + " does not support attachments");
    }
}
