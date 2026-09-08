# Petclinic Production — Alerting, SLI & SLO Reference

This document describes the `petclinic-alerts-prod` `PrometheusRule` resource, which defines the recording rules, Service Level Indicators (SLIs), Service Level Objectives (SLOs), and alerting rules for the Petclinic **production** environment.

- **Resource name:** `petclinic-alerts-prod`
- **Namespace:** `monitoring`
- **Label:** `release: kube-prometheus-stack` (required for Prometheus Operator discovery)
- **Rule groups:** `petclinic.prod.operational`, `petclinic.prod.business_sli`

---

## Table of Contents

- [Concepts: SLI vs. SLO](#concepts-sli-vs-slo)
- [Rule Group: Operational](#rule-group-petclinicprodoperational)
- [Rule Group: Business SLI](#rule-group-petclinicprodbusiness_sli)
  - [Add Visit](#add-visit-post-ownersowneridpetspetidvisitsnew)
  - [Find Owner](#find-owner-get-ownersfind)
  - [Add Pet](#add-pet-post-ownersowneridpetsnew)
- [Alert Summary Table](#alert-summary-table)
- [Recording Rule Summary Table](#recording-rule-summary-table)
- [Design Notes](#design-notes)

---

## Concepts: SLI vs. SLO

| Term | Meaning in this ruleset |
|---|---|
| **SLI** (Service Level Indicator) | A precomputed metric that measures a specific dimension of behavior — e.g., the percentage of requests that completed within 1 second. Implemented as Prometheus **recording rules** with the `_sli`, `_p95`, or `success_rate` suffixes. |
| **SLO** (Service Level Objective) | A target threshold applied to an SLI over a defined window (5 minutes for fast detection, 30 days for a rolling reliability target). Implemented as **alerting rules** that fire when the SLI falls outside the objective. |

Each business operation tracked in this ruleset (Add Visit, Find Owner, Add Pet) follows the same four-part pattern:

1. **Latency SLI (5m)** — % of requests completing within 1 second, short window.
2. **Latency SLI (30d)** — same measurement, rolling 30-day window (used for the formal SLO).
3. **Latency P95 (5m)** — the actual 95th-percentile response time in seconds.
4. **Success Rate SLI (5m and 30d)** — % of requests returning the expected "successful" HTTP status.

---

## Rule Group: `petclinic.prod.operational`

Covers infrastructure-level health: process availability, error rates, and resource saturation.

### `PetclinicAppDown` (Alert)

| Field | Value |
|---|---|
| Expression | `up{environment="petclinic-prod"} == 0` |
| For | 2 minutes |
| Severity | **Critical** |
| Meaning | Prometheus has been unable to scrape the Petclinic production target for 2 consecutive minutes — the application is likely down or unreachable. |

### `petclinic:http_requests_5xx:rate5m` (Recording Rule)

| Field | Value |
|---|---|
| Expression | `sum by (environment) (rate(http_server_requests_seconds_count{environment="petclinic-prod", status=~"5.."}[5m]))` |
| Meaning | The number of HTTP 5xx errors occurring per second, averaged over the last 5 minutes. |

### `PetclinicHigh5xxRate` (Alert)

| Field | Value |
|---|---|
| Expression | 5xx request rate ÷ total request rate × 100 > 5 |
| For | 5 minutes |
| Severity | Warning |
| Meaning | More than 5% of all production HTTP requests are returning server errors (5xx) for a sustained 5-minute period. |

### `petclinic:memory_saturation:5m` (Recording Rule)

| Field | Value |
|---|---|
| Expression | Sum of container working-set memory ÷ sum of configured memory limits × 100 |
| Meaning | The percentage of the pods' configured memory limit currently in use, namespace-wide. |

### `PetclinicHighMemorySaturation` (Alert)

| Field | Value |
|---|---|
| Expression | `petclinic:memory_saturation:5m >= 95` |
| For | 10 minutes |
| Severity | Warning |
| Meaning | Memory usage has stayed at or above 95% of the configured limit for 10 minutes — risk of OOM-kills. |

### `petclinic:cpu_saturation:5m` (Recording Rule)

| Field | Value |
|---|---|
| Expression | Sum of CPU usage rate ÷ sum of configured CPU limits × 100 |
| Meaning | The percentage of the pods' configured CPU limit currently in use, namespace-wide. |

### `PetclinicHighCPUSaturation` (Alert)

| Field | Value |
|---|---|
| Expression | `petclinic:cpu_saturation:5m >= 95` |
| For | 10 minutes |
| Severity | Warning |
| Meaning | CPU usage has stayed at or above 95% of the configured limit for 10 minutes — risk of throttling. |

---

## Rule Group: `petclinic.prod.business_sli`

Covers three critical user-facing business operations. Each has an identical structure of recording rules feeding into SLO-breach alerts.

### Add Visit (`POST /owners/{ownerId}/pets/{petId}/visits/new`)

**Latency**

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:add_visit:latency_sli:5m` | Recording | 5m | % of Add Visit requests completing in ≤ 1.0s |
| `petclinic:add_visit:latency_sli:30d` | Recording | 30d | Same, rolling 30-day window (the formal SLI for the SLO) |
| `petclinic:add_visit:latency_p95:seconds` | Recording | 5m | Actual P95 latency in seconds |
| `PetclinicAddVisitLatencySLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `latency_sli:30d < 99` — fewer than 99% of Add Visit calls complete within 1 second over 30 days |
| `PetclinicAddVisitSlow` | **Alert** (warning, 10m) | 5m | Fires when P95 latency exceeds 1 second for 10 minutes |

**Success rate** (success = HTTP `302` redirect, indicating a valid form submission)

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:add_visit:success_rate:5m` | Recording | 5m | % of requests returning HTTP 302 |
| `petclinic:add_visit:success_rate:30d` | Recording | 30d | Same, rolling 30-day window |
| `PetclinicAddVisitSuccessRateLow` | **Alert** (critical, 10m) | 5m | Fires when `success_rate:5m < 99.9` — immediate, fast-detection breach |
| `PetclinicAddVisitSuccessSLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `success_rate:30d < 99.9` — longer-term SLO breach |

### Find Owner (`GET /owners/find`)

**Latency**

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:find_owner:latency_sli:5m` | Recording | 5m | % of Find Owner requests completing in ≤ 1.0s |
| `petclinic:find_owner:latency_sli:30d` | Recording | 30d | Same, rolling 30-day window |
| `petclinic:find_owner:latency_p95:seconds` | Recording | 5m | Actual P95 latency in seconds |
| `PetclinicFindOwnerLatencySLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `latency_sli:30d < 99` |
| `PetclinicFindOwnerSlow` | **Alert** (warning, 10m) | 5m | Fires when P95 latency exceeds 1 second for 10 minutes |

**Success rate** (success = HTTP `200`, indicating results were returned)

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:find_owner:success_rate:5m` | Recording | 5m | % of requests returning HTTP 200 |
| `petclinic:find_owner:success_rate:30d` | Recording | 30d | Same, rolling 30-day window |
| `PetclinicFindOwnerSuccessRateLow` | **Alert** (critical, 10m) | 5m | Fires when `success_rate:5m < 99.9` |
| `PetclinicFindOwnerSuccessSLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `success_rate:30d < 99.9` |

### Add Pet (`POST /owners/{ownerId}/pets/new`)

**Latency**

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:add_pet:latency_sli:5m` | Recording | 5m | % of Add Pet requests completing in ≤ 1.0s |
| `petclinic:add_pet:latency_sli:30d` | Recording | 30d | Same, rolling 30-day window |
| `petclinic:add_pet:latency_p95:seconds` | Recording | 5m | Actual P95 latency in seconds |
| `PetclinicAddPetLatencySLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `latency_sli:30d < 99` |
| `PetclinicAddPetSlow` | **Alert** (warning, 10m) | 5m | Fires when P95 latency exceeds 1 second for 10 minutes |

**Success rate** (success = any HTTP `2xx` response)

| Rule | Type | Window | Definition |
|---|---|---|---|
| `petclinic:add_pet:success_rate:5m` | Recording | 5m | % of requests returning HTTP 2xx |
| `petclinic:add_pet:success_rate:30d` | Recording | 30d | Same, rolling 30-day window |
| `PetclinicAddPetSuccessRateLow` | **Alert** (critical, 10m) | 5m | Fires when `success_rate:5m < 99.9` |
| `PetclinicAddPetSuccessSLOBreach` | **Alert** (warning, 10m) | 30d | Fires when `success_rate:30d < 99.9` |

> **Note:** Add Pet's success definition (`2xx`) is broader than Add Visit's (`302` only) and Find Owner's (`200` only). This reflects differences in each endpoint's expected response behavior and should be verified against actual application behavior if these thresholds are revisited.

---

## Alert Summary Table

| Alert | Group | Severity | Trigger Condition | For |
|---|---|---|---|---|
| `PetclinicAppDown` | Operational | Critical | Target scrape failing | 2m |
| `PetclinicHigh5xxRate` | Operational | Warning | 5xx rate > 5% of total requests | 5m |
| `PetclinicHighMemorySaturation` | Operational | Warning | Memory usage ≥ 95% of limit | 10m |
| `PetclinicHighCPUSaturation` | Operational | Warning | CPU usage ≥ 95% of limit | 10m |
| `PetclinicAddVisitLatencySLOBreach` | Business SLI | Warning | 30d latency SLI < 99% | 10m |
| `PetclinicAddVisitSlow` | Business SLI | Warning | P95 latency > 1s | 10m |
| `PetclinicAddVisitSuccessRateLow` | Business SLI | Critical | 5m success rate < 99.9% | 10m |
| `PetclinicAddVisitSuccessSLOBreach` | Business SLI | Warning | 30d success rate < 99.9% | 10m |
| `PetclinicFindOwnerLatencySLOBreach` | Business SLI | Warning | 30d latency SLI < 99% | 10m |
| `PetclinicFindOwnerSlow` | Business SLI | Warning | P95 latency > 1s | 10m |
| `PetclinicFindOwnerSuccessRateLow` | Business SLI | Critical | 5m success rate < 99.9% | 10m |
| `PetclinicFindOwnerSuccessSLOBreach` | Business SLI | Warning | 30d success rate < 99.9% | 10m |
| `PetclinicAddPetLatencySLOBreach` | Business SLI | Warning | 30d latency SLI < 99% | 10m |
| `PetclinicAddPetSlow` | Business SLI | Warning | P95 latency > 1s | 10m |
| `PetclinicAddPetSuccessRateLow` | Business SLI | Critical | 5m success rate < 99.9% | 10m |
| `PetclinicAddPetSuccessSLOBreach` | Business SLI | Warning | 30d success rate < 99.9% | 10m |

**Note on severity pattern:** Across all three business operations, the *5-minute* success-rate check is `severity: critical` (fast, real-time detection of an active incident), while the *30-day* rolling success-rate and latency SLO breaches are `severity: warning` (slower-moving reliability trend indicators). This is intentional: a short-term dip demands immediate attention, while a rolling-window breach signals a trend worth investigating but not necessarily paging urgently.

## Recording Rule Summary Table

| Recording Rule | Group | Formula Summary |
|---|---|---|
| `petclinic:http_requests_5xx:rate5m` | Operational | 5xx requests/sec (5m rate) |
| `petclinic:memory_saturation:5m` | Operational | working-set memory ÷ memory limit × 100 |
| `petclinic:cpu_saturation:5m` | Operational | CPU usage rate ÷ CPU limit × 100 |
| `petclinic:add_visit:latency_sli:5m` / `:30d` | Business SLI | % of Add Visit requests ≤ 1.0s |
| `petclinic:add_visit:latency_p95:seconds` | Business SLI | P95 Add Visit latency (5m) |
| `petclinic:add_visit:success_rate:5m` / `:30d` | Business SLI | % of Add Visit requests returning HTTP 302 |
| `petclinic:find_owner:latency_sli:5m` / `:30d` | Business SLI | % of Find Owner requests ≤ 1.0s |
| `petclinic:find_owner:latency_p95:seconds` | Business SLI | P95 Find Owner latency (5m) |
| `petclinic:find_owner:success_rate:5m` / `:30d` | Business SLI | % of Find Owner requests returning HTTP 200 |
| `petclinic:add_pet:latency_sli:5m` / `:30d` | Business SLI | % of Add Pet requests ≤ 1.0s |
| `petclinic:add_pet:latency_p95:seconds` | Business SLI | P95 Add Pet latency (5m) |
| `petclinic:add_pet:success_rate:5m` / `:30d` | Business SLI | % of Add Pet requests returning HTTP 2xx |

---

## Design Notes

- **Two time horizons per SLI:** The `5m` windows exist for fast anomaly detection and real-time dashboards; the `30d` windows exist to evaluate compliance against a formal SLO over a meaningful rolling period, smoothing out short-term noise.
- **Latency threshold:** All three business operations share a 1-second latency target and a 99% latency SLO (i.e., at least 99% of requests should complete within 1 second over 30 days).
- **Success-rate threshold:** All three business operations share a 99.9% success SLO, though the definition of "success" differs per endpoint (`302`, `200`, or `2xx`) based on expected behavior.
- **`for` durations:** Operational alerts mostly use 10-minute `for` clauses (except `PetclinicAppDown` at 2m and `PetclinicHigh5xxRate` at 5m) to avoid alerting on transient spikes.
- **Recording rules as building blocks:** Every alert in the Business SLI group is built on top of a recording rule rather than embedding the full PromQL expression inline. This keeps alert expressions simple, ensures dashboards and alerts stay consistent, and reduces Prometheus query load by precomputing expensive aggregations.
- **Route to Grafana/dashboards:** All `petclinic:*` recording rules are namespaced with a colon-delimited convention (`petclinic:<operation>:<metric>:<window>`) suitable for direct reuse in Grafana dashboard queries.