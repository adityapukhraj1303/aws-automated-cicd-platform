#!/usr/bin/env bats
# ==============================================================================
# Bats Test Suite: API, Version, Metrics & Error Handling
# ==============================================================================

load helpers.bash

@test "GET /version returns HTTP 200 OK and version payload" {
    run send_mock_http_request "GET" "/version"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]

    body="$(extract_http_body "$output")"
    [[ "$body" =~ "\"version\":" ]]
    [[ "$body" =~ "\"service\":\"aws-automated-cicd-platform\"" ]]
}

@test "GET /api/info returns platform and runtime metadata" {
    run send_mock_http_request "GET" "/api/info"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]

    body="$(extract_http_body "$output")"
    [[ "$body" =~ "\"runtime\":\"Bash/Alpine/socat\"" ]]
    [[ "$body" =~ "\"aws_region\":" ]]
    [[ "$body" =~ "\"environment\":" ]]
}

@test "GET /api/metrics returns Prometheus formatted exposition" {
    run send_mock_http_request "GET" "/api/metrics"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]

    body="$(extract_http_body "$output")"
    [[ "$body" =~ "app_uptime_seconds" ]]
    [[ "$body" =~ "app_status 1" ]]
    [[ "$body" =~ "http_requests_total" ]]
}

@test "GET / returns HTTP 200 OK with HTML content" {
    run send_mock_http_request "GET" "/"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 200 ]

    body="$(extract_http_body "$output")"
    [[ "$body" =~ "<!DOCTYPE html>" ]]
    [[ "$body" =~ "AWS Automated CI/CD Platform" ]]
}

@test "GET /non-existent-route returns HTTP 404 Not Found" {
    run send_mock_http_request "GET" "/non-existent-route"
    [ "$status" -eq 0 ]
    
    http_code="$(extract_http_status "$output")"
    [ "$http_code" -eq 404 ]

    body="$(extract_http_body "$output")"
    [[ "$body" =~ "\"error\":\"Not Found\"" ]]
    [[ "$body" =~ "\"status\":404" ]]
}
