package com.healthcare.portal.service;

import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.portal.domain.entity.PractitionerAvailabilitySlot;
import com.healthcare.portal.dto.AvailabilitySlotRequest;
import com.healthcare.portal.repository.PractitionerAvailabilitySlotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AvailabilityService {

    private final PractitionerAvailabilitySlotRepository slotRepo;

    @Transactional(readOnly = true)
    public List<PractitionerAvailabilitySlot> getSlotsForMonth(UUID practitionerId, int year, int month) {
        LocalDate from = LocalDate.of(year, month, 1);
        LocalDate to   = from.withDayOfMonth(from.lengthOfMonth());
        return slotRepo.findByPractitionerIdAndSlotDateBetweenOrderBySlotDateAscStartTimeAsc(practitionerId, from, to);
    }

    @Transactional(readOnly = true)
    public List<PractitionerAvailabilitySlot> getAvailableSlots(UUID practitionerId, LocalDate date) {
        return slotRepo.findAvailableSlots(practitionerId, date);
    }

    @Transactional
    public PractitionerAvailabilitySlot addSlot(UUID practitionerId, AvailabilitySlotRequest req) {
        PractitionerAvailabilitySlot slot = new PractitionerAvailabilitySlot();
        slot.setPractitionerId(practitionerId);
        slot.setSlotDate(req.slotDate());
        slot.setStartTime(req.startTime());
        slot.setEndTime(req.endTime());
        slot.setSlotType(req.slotType() != null ? req.slotType() : "regular");
        slot.setAvailable(!"leave".equals(req.slotType()) && !"blocked".equals(req.slotType()));
        slot.setRecurrenceRule(req.recurrenceRule());
        slot.setMaxAppointments(req.maxAppointments() != null ? req.maxAppointments() : (short) 1);
        slot.setNotes(req.notes());
        return slotRepo.save(slot);
    }

    @Transactional
    public PractitionerAvailabilitySlot blockSlot(UUID slotId, String slotType, String notes) {
        PractitionerAvailabilitySlot slot = slotRepo.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("AvailabilitySlot", slotId));
        slot.setAvailable(false);
        slot.setSlotType(slotType != null ? slotType : "blocked");
        slot.setNotes(notes);
        return slotRepo.save(slot);
    }

    @Transactional
    public void deleteSlot(UUID slotId) {
        PractitionerAvailabilitySlot slot = slotRepo.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("AvailabilitySlot", slotId));
        if (slotRepo.isSlotBooked(slotId)) {
            throw new IllegalStateException("Cannot delete a slot that has a booked appointment");
        }
        slotRepo.delete(slot);
    }
}