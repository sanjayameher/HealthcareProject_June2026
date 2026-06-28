package com.healthcare.portal.dto;

import java.util.UUID;

public record InviteResponse(
        UUID accountId,
        String role,
        String inviteToken
) {}