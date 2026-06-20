package com.healthcare.billing.repository;

import com.healthcare.billing.domain.entity.Payer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface PayerRepository extends JpaRepository<Payer, UUID> {
}
