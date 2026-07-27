package com.healthcare.cds.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "cds")
@Getter
@Setter
public class CdsProperties {

    private Groq groq = new Groq();
    private Ollama ollama = new Ollama();
    private Jwt jwt = new Jwt();
    private Services services = new Services();

    @Getter @Setter
    public static class Groq {
        private String apiKey = "";
        private String model = "llama-3.3-70b-versatile";
        private int maxTokens = 2048;
    }

    @Getter @Setter
    public static class Ollama {
        private String url = "http://localhost:11434";
        private String embeddingModel = "nomic-embed-text";
        private int embeddingDimension = 768;
    }

    @Getter @Setter
    public static class Jwt {
        private String secret = "";
    }

    @Getter @Setter
    public static class Services {
        private String patientServiceUrl = "http://localhost:7081";
        private String clinicalServiceUrl = "http://localhost:7082";
    }
}