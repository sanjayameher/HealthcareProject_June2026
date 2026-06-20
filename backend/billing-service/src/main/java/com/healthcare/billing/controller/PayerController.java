package com.healthcare.billing.controller;

import com.healthcare.billing.domain.entity.Payer;
import com.healthcare.billing.repository.PayerRepository;
import com.healthcare.common.dto.ApiResponse;
import com.healthcare.common.exception.ResourceNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payers")
@RequiredArgsConstructor
@Tag(name = "Payers", description = "Insurance payer registry management")
public class PayerController {

    private final PayerRepository payerRepository;

    @GetMapping
    @Operation(summary = "List all payers")
    public ResponseEntity<ApiResponse<List<Payer>>> getAllPayers() {
        return ResponseEntity.ok(ApiResponse.ok(payerRepository.findAll()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get payer by ID")
    public ResponseEntity<ApiResponse<Payer>> getPayerById(@PathVariable UUID id) {
        Payer payer = payerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Payer", id));
        return ResponseEntity.ok(ApiResponse.ok(payer));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new payer")
    public ResponseEntity<ApiResponse<Payer>> createPayer(@RequestBody Payer payer) {
        Payer saved = payerRepository.save(payer);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(saved));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a payer")
    public ResponseEntity<Void> deletePayer(@PathVariable UUID id) {
        if (!payerRepository.existsById(id)) {
            throw new ResourceNotFoundException("Payer", id);
        }
        payerRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
