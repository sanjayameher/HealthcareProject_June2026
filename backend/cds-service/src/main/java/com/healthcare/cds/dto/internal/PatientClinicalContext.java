package com.healthcare.cds.dto.internal;

import java.util.List;

/**
 * Anonymized patient context passed to the LLM — deliberately excludes name, MRN,
 * and any other direct identifier. Only age, gender, and clinical text are used.
 */
public record PatientClinicalContext(
        Integer ageYears,
        String gender,
        List<String> recentEncounterSummaries
) {}
