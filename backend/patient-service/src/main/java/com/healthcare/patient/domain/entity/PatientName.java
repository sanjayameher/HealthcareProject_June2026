package com.healthcare.patient.domain.entity;

import com.healthcare.patient.domain.enums.NameUse;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "patient_names")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientName {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.name_use")
    @Enumerated(EnumType.STRING)
    @Column(name = "use", columnDefinition = "dev.name_use")
    private NameUse use;

    @Column(name = "family", nullable = false)
    private String family;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "given", columnDefinition = "TEXT[]")
    private String[] given;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "prefix", columnDefinition = "TEXT[]")
    private String[] prefix;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "suffix", columnDefinition = "TEXT[]")
    private String[] suffix;

    @Column(name = "text")
    private String text;

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @PrePersist
    void prePersist() {
        if (this.text == null && this.given != null && this.family != null) {
            this.text = String.join(" ", this.given) + " " + this.family;
        }
    }
}
