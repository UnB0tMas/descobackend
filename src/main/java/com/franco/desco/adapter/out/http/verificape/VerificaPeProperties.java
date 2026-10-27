package com.franco.desco.adapter.out.http.verificape;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.verificape")
public class VerificaPeProperties {

    private boolean enabled = true;
    private String baseUrl;
    private String apiKey;
    private String dniPath;
    private String rucPath;
    private int connectTimeoutMs = 5000;
    private int readTimeoutMs = 8000;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getDniPath() {
        return dniPath;
    }

    public void setDniPath(String dniPath) {
        this.dniPath = dniPath;
    }

    public String getRucPath() {
        return rucPath;
    }

    public void setRucPath(String rucPath) {
        this.rucPath = rucPath;
    }

    public int getConnectTimeoutMs() {
        return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(int connectTimeoutMs) {
        this.connectTimeoutMs = connectTimeoutMs;
    }

    public int getReadTimeoutMs() {
        return readTimeoutMs;
    }

    public void setReadTimeoutMs(int readTimeoutMs) {
        this.readTimeoutMs = readTimeoutMs;
    }

    public boolean configured() {
        return enabled
                && hasText(baseUrl)
                && hasText(apiKey)
                && !apiKey.startsWith("REEMPLAZAR_")
                && hasText(dniPath)
                && hasText(rucPath);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
