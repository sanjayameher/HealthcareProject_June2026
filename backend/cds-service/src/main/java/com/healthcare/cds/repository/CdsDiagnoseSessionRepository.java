package com.healthcare.cds.repository;

import com.healthcare.cds.domain.entity.CdsDiagnoseSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CdsDiagnoseSessionRepository extends JpaRepository<CdsDiagnoseSession, UUID> {
}
