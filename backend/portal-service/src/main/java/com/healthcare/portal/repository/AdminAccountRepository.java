package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.AdminAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AdminAccountRepository extends JpaRepository<AdminAccount, UUID> {

    Optional<AdminAccount> findByEmail(String email);

    boolean existsByEmail(String email);
}