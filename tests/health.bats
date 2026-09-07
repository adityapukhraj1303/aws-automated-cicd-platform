#!/usr/bin/env bats
# ==============================================================================
# Bats Test Suite: Health Check & Probes
# ==============================================================================

load helpers.bash

@test "GET /health returns HTTP 200 OK" {
    run send_mock_http_request "GET" "/health"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]
}

@test "GET /health returns valid JSON with status 'ok'" {
    run send_mock_http_request "GET" "/health"
    [ "$status" -eq 0 ]

    body="$(extract_http_body "$output")"
    
    # Assert JSON payload contains mandatory fields
    [[ "$body" =~ "\"status\":\"ok\"" ]]
    [[ "$body" =~ "\"service\":\"aws-automated-cicd-platform\"" ]]
    [[ "$body" =~ "\"uptime_seconds\":" ]]
    [[ "$body" =~ "\"timestamp\":" ]]
}

@test "GET /healthz alias returns HTTP 200 OK" {
    run send_mock_http_request "GET" "/healthz"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]
    
    body="$(extract_http_body "$output")"
    [[ "$body" =~ "\"status\":\"ok\"" ]]
}
