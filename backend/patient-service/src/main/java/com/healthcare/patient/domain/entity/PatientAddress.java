package com.healthcare.patient.domain.entity;

import com.healthcare.patient.domain.enums.AddressType;
import com.healthcare.patient.domain.enums.AddressUse;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "patient_addresses")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientAddress {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.address_use")
    @Enumerated(EnumType.STRING)
    @Column(name = "use", columnDefinition = "dev.address_use")
    private AddressUse use;

    @ColumnTransformer(write = "?::dev.address_type")
    @Enumerated(EnumType.STRING)
    @Column(name = "type", columnDefinition = "dev.address_type")
    private AddressType type;

    @Column(name = "line1")
    private String line1;

    @Column(name = "line2")
    private String line2;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "district", length = 100)
    private String district;

    @Column(name = "state", length = 2)
    private String state;

    @Column(name = "postal_code", length = 10)
    private String postalCode;

    @Column(name = "country", length = 2)
    private String country = "US";

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;
}
