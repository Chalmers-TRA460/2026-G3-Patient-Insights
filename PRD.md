# Patient Insights
## Product Requirements Document

> **TRA460: Digital Health Implementation** | Chalmers University of Technology

---

### Project Details

| Field               | Value                                      |
|---------------------|--------------------------------------------|
| **Group**           | TRA460_Group_3                             |
| **Version**         | 2.0                                        |
<<<<<<< Updated upstream
| **Date**            | 2026-06-04                                 |
=======
| **Date**            | 2026-05-12                                 |
>>>>>>> Stashed changes
| **Clinical Mentor** | Sara Hansson, Specialist in anesthesia and intensive care, Sahlgrenska University Hospital |
| **Group Members**   | Xiaoyu Chen (MPSOF), Xiyu Du (MPSOF), Nathalie Hogberg (MPCAS), Sugash Krishnamoorthy (MPDSC) |

---

## 1. Needs Statement

<!--
  REQUIRED FOR v1.0

  THE CORE OF YOUR PRD.
  Use the Stanford Biodesign format below. Be specific:
  - The verb should describe a function, not a technology.
  - The population should be narrow enough to be actionable.
  - The outcome should be measurable or clearly observable.

  Weak:  "A way to use AI for patients that improves healthcare."
  Strong: "A way to detect early signs of atrial fibrillation
           in post-stroke patients managed in primary care
           that reduces time-to-treatment for recurrent events."
-->

> **A way to** provide accessible and understandable health information
<<<<<<< Updated upstream
> **for** adult patients who struggle to retain information from clinical encounters
> **that** improves their ability to follow their care plan.
=======
> **for** adult patients who struggle to access and/or understand their health information
> **that** improves patient understanding of and adherence to their care plan.
>>>>>>> Stashed changes

---

### 1.1 Clinical Context & Background

<!--
  REQUIRED FOR v1.0

  Set the stage. What is the clinical problem space?
  - What condition, workflow, or care gap are you addressing?
  - How significant is this problem? (incidence, prevalence, burden)
  - Why does it matter — clinically, economically, or humanly?
-->

During clinical visits, patients often struggle to understand the medical terminology used by healthcare professionals. Even when explanations are provided verbally, many patients find it difficult to recall the information and instructions after the visit. As a result, they may not fully understand their diagnosis, treatment plan, or follow-up recommendations, which can lead to reduced adherence to medical advice.

While patients in Sweden can access their health journals through 1177, these records are written for clinicians, not patients. The language used in the notes is therefore difficult for anyone without a medical background to understand. As a result, many patients struggle with the current system, regardless of age or digital literacy. This makes it difficult to revisit what was discussed during the visit, making it harder to adhere to the provided care plan. 

When patients are uncertain about what they are supposed to do, they often contact the clinic for clarification. These follow-up calls result in additional work for clinicians between and after appointments, adding to the already high workload. 

### 1.2 Key Clinical Insights

<!--
  REQUIRED FOR v1.0

  THIS IS THE MOST IMPORTANT SECTION FOR v1.0.
  Synthesize what you learned from your clinical mentor meeting(s).
  - What did you observe or hear?
  - What is the current workflow / status quo?
  - Where are the friction points, inefficiencies, or risks?
  - What surprised you?

  Ground this in specifics. Quotes, scenarios, and concrete
  examples are more valuable than generalizations.
-->

#### **Observations & Current Workflow:**
Currently, medical records are designed and written primarily for medical professionals, rather than for the patients receiving the care. While patients have the ability to access their medical records online through the 1177.se portal, the system is difficult to navigate and the medical language used is not always easy for a layperson to understand. During a meeting with our clinical mentor Sara Hansson, she mentioned that she often writes down instructions on paper to give to patients at the end of the visit, as a way to support understanding and adherence. This highlights the limitations of the existing digital tools. 

#### **Friction Points & Inefficiencies:**
The core friction point lies in the communication gap between the clinic and the patient's everyday life. Specifically:

**Lack of Clinical Verification**: Physicians currently lack a reliable feedback loop to ensure the patient has actually understood the critical information they intended to communicate.

**The "Care Circle" Gap**: Patients often rely on their support network, but relatives and friends lack a reliable way to understand what the physician communicated, especially if the patient themselves did not fully grasp the information during the visit.

### 1.3 Existing Solutions & Gaps

<!--
  REQUIRED FOR v1.0

  What solutions or tools exist today for this problem?
  - Clinical tools, apps, devices, workflows
  - Why are they insufficient, inaccessible, or underused?
  - What gap remains that your project could fill?
-->

Patients can access their journals and the doctor's notes on 1177 to recall the content of the visits. But there are always terminologies that are hard for the patients to understand. So our project is aimed to bridge the knowledge gap between patients and doctors and create a user-friendly application that is integrated with 1177.

### 1.4 Success Metrics

<!--
  RECOMMENDED FOR v1.0

  How will you know your solution actually addresses the need?
  Think about the "that..." clause in your Needs Statement —
  how would you measure or observe that outcome?
-->

- Improved care plan adherence - This can be measured through indicators such as medication adherence (assessed via patient self-report or prescription refill data) or completion of recommended follow-up actions. 

---

## 2. Stakeholders & Users

### 2.1 Primary User(s)

<!--
   REQUIRED FOR v1.0

  Who will directly use or interact with your solution day-to-day?
  Be specific: "Cardiac nurses in outpatient clinics" not just "nurses."
-->

Adult patients who struggle to retain information from clinical encounters.

### 2.2 Other Stakeholders

<!--
  REQUIRED FOR v1.0

  Who else is affected by or has influence over this solution?
  Consider: patients, caregivers, administrators, IT departments,
  payers/insurers, regulators, clinical champions, etc.
-->

**Family Members and Informal Caregivers**: Relatives or friends who provide support to the patient. They are highly affected stakeholders because they currently lack a reliable way to understand the physician's communication if the patient themselves did not fully grasp it during the visit. They will benefit from the tool's secure sharing features.

**Physicians and Clinical Staff**: The medical professionals who author the original records. While the medical records are primarily written for other professionals, doctors are heavily invested in this solution because they currently lack a way to verify that patients have understood critical care instructions.

**Regional IT Departments**: The organizations responsible for maintaining the national 1177.se infrastructure and regional healthcare databases. They have significant influence over data accessibility, system integration, and security standards.

**Regulatory and Compliance Bodies (e.g., IMY)**: Authorities responsible for enforcing the General Data Protection Regulation (GDPR) and the Swedish Patient Data Act (Patientdatalagen). Since the proposed solution involves extracting and processing sensitive health data through an LLM, these bodies heavily influence the privacy and security requirements of the project.

### 2.3 User Journey — Current State

<!--
  RECOMMENDED FOR v1.0

  Describe the current care pathway or experience of your primary user.
  A simple narrative walkthrough is fine, e.g.:
  "The patient wakes up, measures their..., calls the clinic to..."
-->

The patient has an upcoming visit, so they open the app to prepare for the appointment. On the day of the visit, the patient goes to the clinic and explains their concerns using the preparation they completed beforehand. They then start recording the conversation and discuss the issue with the clinician. At the end of the visit, the patient stops the recording and reviews the generated summary together with the clinician to ansure it is accurate. After the visit, the patient uses the app to follow their care plan. 

---

## 3. Solution Vision

<!--
  REQUIRED FOR v1.0

  1-2 paragraphs maximum. This is your "north star," not a feature list.
  - What is the high-level concept?
  - How does it directly address the Needs Statement?
  - What does success look like from the user's perspective?

  Keep it directional. You will refine this throughout the course.
-->

We propose to build an easy-to-use mobile application that empowers patients to better understand their medical conditions through a clear, accessible summarization of their clinical data. The app will translate complex medical information into patient-friendly language, allowing users to easily review their diagnoses, treatments, and health insights in one place.

Success from the patient's perspective means they can open the app, quickly grasp what's happening with their health, and feel more engaged and confident in managing their condition. This directly reduces confusion and improves health literacy — enabling patients to be active participants in their own care.

---

## 4. Requirements

### 4.1 Functional Requirements (MoSCoW)

<!--
  RECOMMENDED FOR v1.0

  Categorize what your MVP needs to DO.
  Each requirement should be a clear, testable capability.
  A few items per category is enough for v1.0 — this section
  will grow significantly in later iterations.
-->

**Must Have** — *Non-negotiable for a functioning MVP*
- Audio recording of the visit
- AI-generated summary of the visit

**Should Have** — *High value, but the MVP could technically function without these*
- Patient visit preparation
- Quiz to test patient understanding

**Could Have** — *Nice-to-have if time and resources allow*
- Support for more languages
- Overall health summary based on key information from recent visits 

**Won't Have** — *Explicitly out of scope for this project*
- Integration with 1177

### 4.2 Non-Functional Requirements & Constraints

<!--
  RECOMMENDED FOR v1.0

  Consider the "invisible" requirements:
  - Data privacy & security (GDPR, patient data handling)
  - Regulatory considerations (MDR, wellness vs. medical device)
  - Accessibility (WCAG, language/localization)
  - Interoperability standards (FHIR, HL7, openEHR)
  - Performance, offline capability
-->
- GDPR-compliant data handling
- Secure storage of recording and summaries
- Avoid MDR classification (wellness-oriented functionality)
- WCAG-compliant interface
- Standardized data formats for future interoperability
- Efficient summary generation
- Offline recording capability

---

## 5. Technical Direction

<!--
  EXPAND IN LATER ITERATIONS

  Initial thoughts only. No commitments required yet.
  This section helps your future self (and your AI agent, if using
  Claude Code) understand the technical landscape you are considering.
-->

- **Platform:** Android, iOS later
- **Key Integrations:** APIs in the future
- **Candidate Tech Stack:** TBD
- **Infrastructure:** TBD

---

## 6. Open Questions & Risks

<!--
  REQUIRED FOR v1.0

  Be honest about what you don't know yet. This is a sign of
  rigorous thinking, not weakness.
  - What assumptions are you making that haven't been validated?
  - What could block or derail this project?
  - What do you need to ask your clinical mentor next?
-->

- **Risk - GDPR/PDL Data Processing Compliance:** How will we handle patient data through an LLM while ensuring full compliance with Swedish data protection laws?  
  *Plan:* Consult with IMY and legal counsel on data residency, retention, and consent models 

- **Question - 1177 Integration Access:** Can we technically access patient records from 1177.se via API, and what are the barriers (technical, legal, authentication)?  
  *Plan:* Contact regional IT departments managing 1177 infrastructure to explore integration pathways 

- **Question - Clinical Accuracy Verification:** How do we validate that LLM-generated summaries remain clinically accurate and don't misrepresent diagnoses or treatments?  
  *Plan:* Develop a clinical review protocol with Sara Hansson; test on 5–10 real patient records 

- **Risk - Care Circle Consent Model:** What consent framework ensures patients control who can access their shared health information while maintaining privacy?  
  *Plan:* Co-design a consent and sharing policy with clinical mentor and legal input 

- **Risk - Clinical Workflow Integration:** Will physicians and nurses actually use this tool in their existing workflow, or will it add burden?  
  *Plan:* Map current clinical workflow with the department to identify integration points that don't increase clinician workload 

---

## Changelog

| Version | Date       | Summary of Changes                                  |
|---------|------------|-----------------------------------------------------|
| 1.0     | 2026-04-17 | Initial draft after first clinical mentor meeting   |
<<<<<<< Updated upstream
| 2.0     | 2026-06-04 | Revised version based on feedback                   |
=======
| 2.0     | 2026-05-12 | Revised version based on feedback                   |
>>>>>>> Stashed changes
