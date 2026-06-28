package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.PractitionerAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PractitionerAccountRepository extends JpaRepository<PractitionerAccount, UUID> {

    Optional<PractitionerAccount> findByEmailHash(byte[] emailHash);

    Optional<PractitionerAccount> findByPractitionerId(UUID practitionerId);

    boolean existsByEmailHash(byte[] emailHash);
}