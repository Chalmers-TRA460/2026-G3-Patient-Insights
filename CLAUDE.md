# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Patient Insights** — a TRA460 Digital Health Implementation course project (Chalmers University of Technology, Group 3).

**Goal:** A mobile app that translates clinical records from 1177.se (Sweden's national patient portal) into plain, patient-friendly language, helping adult patients understand their diagnoses, treatments, and care plans.

**Clinical mentor:** Sara Hansson, Specialist in anesthesia and intensive care, Sahlgrenska University Hospital.

**Group members:** Xiaoyu Chen, Xiyu Du, Nathalie Hogberg, Sugash Krishnamoorthy.

## Current Status

This repository is in the **planning phase** — only `PRD.md` exists. No application code has been written yet. The PRD captures the needs statement, clinical context, and solution vision; functional requirements and technical direction are still being defined.

## Key Clinical Context

- Patients access records via 1177.se, but the interface and medical language are built for clinicians, not laypersons.
- Physicians sometimes hand patients paper notes as a workaround — there is no reliable feedback loop to confirm patient comprehension.
- Family members/caregivers also lack a reliable way to understand what was communicated.
- Swedish regulatory context: GDPR + Patientdatalagen (Swedish Patient Data Act) apply. IMY is the supervisory authority. Processing health data through an LLM requires careful compliance planning.

## Planning Skills (from parent repo)

Skills are available in the parent `TRA460_Group_3` workspace. Invoke them in Claude Code with `/skill-name`:

| Next step | Skill |
|---|---|
| Refine the need statement | `/biodesign-needs-finding` |
| Choose platform (React Native vs. Apple/Spezi) | `/spezi-platform-selection` |
| Design user journeys and onboarding | `/digital-health-ux-planning` |
| Model health data entities | `/health-data-model-planning` |
| Map to FHIR R4 resources | `/fhir-data-model-design` |
| Address GDPR / PDL / IRB compliance | `/digital-health-compliance-planning` |
| Plan any research protocol | `/digital-health-study-planning` |
| Generate implementation plan from planning docs | `/app-build-planner` |

Planning outputs land in `docs/planning/`. Implementation plan lands in `docs/implementation-plan.md`.

## Source of Truth

`PRD.md` is the authoritative project document. All planning decisions should be traceable back to or reflected in it.
