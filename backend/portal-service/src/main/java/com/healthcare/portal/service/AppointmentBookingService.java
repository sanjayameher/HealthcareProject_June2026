package com.healthcare.portal.service;

import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.portal.domain.entity.Appointment;
import com.healthcare.portal.domain.entity.AppointmentParticipant;
import com.healthcare.portal.domain.entity.PractitionerAvailabilitySlot;
import com.healthcare.portal.dto.BookAppointmentRequest;
import com.healthcare.portal.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AppointmentBookingService {

    private final AppointmentRepository appointmentRepo;
    private final AppointmentParticipantRepository participantRepo;
    private final PractitionerAvailabilitySlotRepository slotRepo;
    private final NotificationService notificationService;

    @Transactional
    public Appointment bookAppointment(BookAppointmentRequest req) {
        PractitionerAvailabilitySlot slot = slotRepo.findById(req.slotId())
                .orElseThrow(() -> new ResourceNotFoundException("AvailabilitySlot", req.slotId()));

        if (!slot.isAvailable()) {
            throw new IllegalStateException("Slot is no longer available");
        }

        // Create appointment
        Appointment apt = new Appointment();
        apt.setPatientId(req.patientId());
        apt.setStatus("booked");
        apt.setStartTime(req.startTime());
        apt.setEndTime(req.endTime());
        apt.setSlotId(req.slotId());
        apt.setAppointmentTypeCode(req.appointmentTypeCode() != null ? req.appointmentTypeCode() : "ROUTINE");
        apt.setDescription(req.description());
        apt = appointmentRepo.save(apt);

        // Practitioner participant
        AppointmentParticipant pracPart = new AppointmentParticipant();
        pracPart.setAppointmentId(apt.getId());
        pracPart.setTypeCode("ATND");
        pracPart.setTypeDisplay("Attender");
        pracPart.setActorPractitionerId(req.practitionerId());
        pracPart.setStatus("accepted");
        participantRepo.save(pracPart);

        // Patient participant
        AppointmentParticipant patPart = new AppointmentParticipant();
        patPart.setAppointmentId(apt.getId());
        patPart.setTypeCode("PART");
        patPart.setTypeDisplay("Participant");
        patPart.setActorPatientId(req.patientId());
        patPart.setStatus("accepted");
        participantRepo.save(patPart);

        // Mark slot as booked
        slot.setAvailable(false);
        slotRepo.save(slot);

        // Notifications
        notificationService.notifyPatient(req.patientId(), "appointment_booked",
                "Appointment Confirmed", "Your appointment has been booked for " + req.startTime());
        notificationService.notifyPractitioner(req.practitionerId(), "appointment_assigned",
                "New Appointment Assigned", "A new appointment has been assigned to you on " + req.startTime());

        return apt;
    }

    @Transactional
    public Appointment cancelAppointment(UUID appointmentId) {
        Appointment apt = appointmentRepo.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", appointmentId));
        apt.setStatus("cancelled");
        apt.setCancellationReason("Cancelled by user");
        final Appointment saved = appointmentRepo.save(apt);

        // Free up the slot
        if (saved.getSlotId() != null) {
            slotRepo.findById(saved.getSlotId()).ifPresent(slot -> {
                slot.setAvailable(true);
                slotRepo.save(slot);
            });
        }

        // Cancellation notifications
        notificationService.notifyPatient(saved.getPatientId(), "appointment_cancelled",
                "Appointment Cancelled", "Your appointment on " + saved.getStartTime() + " has been cancelled.");

        List<AppointmentParticipant> participants = participantRepo.findByAppointmentId(appointmentId);
        participants.stream()
                .filter(p -> p.getActorPractitionerId() != null)
                .forEach(p -> notificationService.notifyPractitioner(p.getActorPractitionerId(),
                        "appointment_cancelled", "Appointment Cancelled",
                        "An appointment on " + saved.getStartTime() + " has been cancelled."));

        return saved;
    }

    @Transactional
    public Appointment updateStatus(UUID appointmentId, String newStatus, UUID reassignPractitionerId) {
        Appointment apt = appointmentRepo.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", appointmentId));
        apt.setStatus(newStatus);
        apt = appointmentRepo.save(apt);

        if (reassignPractitionerId != null) {
            participantRepo.deletePractitionerParticipants(appointmentId);
            AppointmentParticipant newPrac = new AppointmentParticipant();
            newPrac.setAppointmentId(appointmentId);
            newPrac.setTypeCode("ATND");
            newPrac.setTypeDisplay("Attender");
            newPrac.setActorPractitionerId(reassignPractitionerId);
            newPrac.setStatus("accepted");
            participantRepo.save(newPrac);
        }

        return apt;
    }

    @Transactional(readOnly = true)
    public List<Appointment> getTodaysQueue() {
        OffsetDateTime startOfDay = OffsetDateTime.now().toLocalDate().atStartOfDay().atOffset(OffsetDateTime.now().getOffset());
        OffsetDateTime endOfDay   = startOfDay.plusDays(1);
        return appointmentRepo.findUpcomingForPatient(null, startOfDay, endOfDay)
                .stream()
                .filter(a -> List.of("booked", "arrived", "checked_in").contains(a.getStatus()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<Appointment> getTodaysQueueForDoctor(UUID practitionerId) {
        OffsetDateTime startOfDay = OffsetDateTime.now().toLocalDate().atStartOfDay().atOffset(OffsetDateTime.now().getOffset());
        OffsetDateTime endOfDay   = startOfDay.plusDays(1);
        List<UUID> appointmentIds = participantRepo.findAppointmentIdsByPractitionerId(practitionerId);
        return appointmentRepo.findAll().stream()
                .filter(a -> appointmentIds.contains(a.getId()))
                .filter(a -> !a.getStartTime().isBefore(startOfDay) && a.getStartTime().isBefore(endOfDay))
                .toList();
    }
}