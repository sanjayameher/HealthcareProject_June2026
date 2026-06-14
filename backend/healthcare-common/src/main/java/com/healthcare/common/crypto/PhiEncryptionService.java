package com.healthcare.common.crypto;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * AES-256-GCM encryption service for PHI (Protected Health Information).
 *
 * <p>In production: inject key from AWS KMS or HashiCorp Vault.
 * Never store the encryption key in application.yml or source code.
 *
 * <p>Output format (Base64 of): [12-byte IV][encrypted bytes][16-byte auth tag]
 */
@Slf4j
@Service
public class PhiEncryptionService {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;

    private final SecretKey secretKey;

    public PhiEncryptionService(@Value("${healthcare.encryption.key}") String base64Key) {
        byte[] keyBytes = Base64.getDecoder().decode(base64Key);
        this.secretKey = new SecretKeySpec(keyBytes, "AES");
    }

    public byte[] encrypt(String plaintext) {
        if (plaintext == null) return null;
        try {
            byte[] iv = new byte[GCM_IV_LENGTH];
            new SecureRandom().nextBytes(iv);

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

            byte[] encrypted = cipher.doFinal(plaintext.getBytes());
            byte[] result = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, result, 0, iv.length);
            System.arraycopy(encrypted, 0, result, iv.length, encrypted.length);
            return result;
        } catch (Exception e) {
            throw new PhiEncryptionException("Encryption failed", e);
        }
    }

    public String decrypt(byte[] ciphertext) {
        if (ciphertext == null) return null;
        try {
            byte[] iv = new byte[GCM_IV_LENGTH];
            System.arraycopy(ciphertext, 0, iv, 0, iv.length);

            byte[] encrypted = new byte[ciphertext.length - GCM_IV_LENGTH];
            System.arraycopy(ciphertext, GCM_IV_LENGTH, encrypted, 0, encrypted.length);

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));
            return new String(cipher.doFinal(encrypted));
        } catch (Exception e) {
            throw new PhiEncryptionException("Decryption failed", e);
        }
    }

    public byte[] hmac(String value) {
        if (value == null) return null;
        try {
            javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
            mac.init(secretKey);
            return mac.doFinal(value.getBytes());
        } catch (Exception e) {
            throw new PhiEncryptionException("HMAC computation failed", e);
        }
    }

    public static String generateBase64Key() throws Exception {
        KeyGenerator kg = KeyGenerator.getInstance("AES");
        kg.init(256);
        return Base64.getEncoder().encodeToString(kg.generateKey().getEncoded());
    }

    public static class PhiEncryptionException extends RuntimeException {
        public PhiEncryptionException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
