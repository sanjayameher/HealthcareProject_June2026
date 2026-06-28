package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.PractitionerView;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface PractitionerViewRepository extends JpaRepository<PractitionerView, UUID> {

    Page<PractitionerView> findByActive(boolean active, Pageable pageable);

    @Query("""
        SELECT p FROM PractitionerView p
        WHERE p.active = true
          AND (
              LOWER(p.familyName) LIKE LOWER(CONCAT('%', :search, '%'))
           OR LOWER(p.givenName)  LIKE LOWER(CONCAT('%', :search, '%'))
          )
        """)
    Page<PractitionerView> searchActive(String search, Pageable pageable);
}