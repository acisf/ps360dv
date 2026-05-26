# Apex Classes and Flows Referencing Custom Objects

## Summary Report
Generated: 2026-05-26

This report identifies all Apex classes and Flows that reference the following custom objects:
- NVMStatsSF__NVM_Call_Summary__c
- Adherence__c
- Beth_Call_Summary__c
- Existing_Patient_Call__c
- FB_Lead__c
- OAI_Survey__c
- Quality_Monitoring__c
- NVM_PCS__c
- Lead (Standard Object)

---

## 1. NVMStatsSF__NVM_Call_Summary__c (NVM Call Summary)

### Apex Classes (24 classes)

1. **AgentCallEmail.cls** - Queries call summaries for scheduled appointments and email notifications
   - Path: `force-app/main/default/classes/AgentCallEmail.cls`

2. **AgentCallEmailTest.cls** - Test class for AgentCallEmail
   - Path: `force-app/main/default/classes/AgentCallEmailTest.cls`

3. **BackfillFirstCallSummary2026.cls** - Backfills First_Call_Summary__c field on Customer_Inquiry__c
   - Path: `force-app/main/default/classes/BackfillFirstCallSummary2026.cls`

4. **BackfillFirstCallSummary2026_Test.cls** - Test class for backfill logic
   - Path: `force-app/main/default/classes/BackfillFirstCallSummary2026_Test.cls`

5. **BatchCallCenterSummary.cls** - Aggregates call center metrics (abandoned, answered, transfers)
   - Path: `force-app/main/default/classes/BatchCallCenterSummary.cls`

6. **BatchCallCenterSummaryTest.cls** - Test class for call center summary batch
   - Path: `force-app/main/default/classes/BatchCallCenterSummaryTest.cls`

7. **BatchOaiSurvey.cls** - Links OAI surveys to call summaries via CallGuid
   - Path: `force-app/main/default/classes/BatchOaiSurvey.cls`

8. **BatchOaiSurveyTest.cls** - Test class for OAI survey batch
   - Path: `force-app/main/default/classes/BatchOaiSurveyTest.cls`

9. **BatchPCS.cls** - Links NVM_PCS__c records to call summaries
   - Path: `force-app/main/default/classes/BatchPCS.cls`

10. **BatchPCSTest.cls** - Test class for PCS batch
    - Path: `force-app/main/default/classes/BatchPCSTest.cls`

11. **CallSummaryJob.cls** - Scheduled job for processing call summaries
    - Path: `force-app/main/default/classes/CallSummaryJob.cls`

12. **CallSummaryJobTest.cls** - Test class for CallSummaryJob
    - Path: `force-app/main/default/classes/CallSummaryJobTest.cls`

13. **CallSummaryUpdate.cls** - Updates call summary records with task subcategories
    - Path: `force-app/main/default/classes/CallSummaryUpdate.cls`

14. **CallSummaryUpdateTest.cls** - Test class for CallSummaryUpdate
    - Path: `force-app/main/default/classes/CallSummaryUpdateTest.cls`

15. **CnaJob.cls** - CNA (Customer Needs Assessment) tracking job
    - Path: `force-app/main/default/classes/CnaJob.cls`

16. **CnaJobTest.cls** - Test class for CnaJob
    - Path: `force-app/main/default/classes/CnaJobTest.cls`

17. **CnaScheduleJob.cls** - Scheduler for CNA job
    - Path: `force-app/main/default/classes/CnaScheduleJob.cls`

18. **FirstCallResolutionBatch1.cls** - Tracks first call resolution metrics
    - Path: `force-app/main/default/classes/FirstCallResolutionBatch1.cls`

19. **FirstCallResolutionBatch1Test.cls** - Test class for first call resolution
    - Path: `force-app/main/default/classes/FirstCallResolutionBatch1Test.cls`

20. **ScheduleCallSummaryUpdate.cls** - Schedules call summary updates
    - Path: `force-app/main/default/classes/ScheduleCallSummaryUpdate.cls`

21. **ScheduleCallSummaryUpdateBackfillQ12025.cls** - Backfill scheduler for Q1 2025
    - Path: `force-app/main/default/classes/ScheduleCallSummaryUpdateBackfillQ12025.cls`

### Flows (5 flows)

1. **Vonage_Call_Summary_Before_Save.flow-meta.xml** - Record-triggered flow (before save)
   - Path: `force-app/main/default/flows/Vonage_Call_Summary_Before_Save.flow-meta.xml`
   - Trigger: CreateAndUpdate on NVMStatsSF__NVM_Call_Summary__c

2. **Vonage_Call_Summary_After_Save.flow-meta.xml** - Record-triggered flow (after save)
   - Path: `force-app/main/default/flows/Vonage_Call_Summary_After_Save.flow-meta.xml`
   - Trigger: CreateAndUpdate on NVMStatsSF__NVM_Call_Summary__c

3. **NVM_PCS_After_Save.flow-meta.xml** - Queries NVM_Call_Summary__c records
   - Path: `force-app/main/default/flows/NVM_PCS_After_Save.flow-meta.xml`

4. **Quality_Monitoring_Before_Save.flow-meta.xml** - Looks up NVM_Call_Summary__c
   - Path: `force-app/main/default/flows/Quality_Monitoring_Before_Save.flow-meta.xml`

5. **Existing_Patient_Call_Before_Save.flow-meta.xml** - Queries NVM_Call_Summary__c
   - Path: `force-app/main/default/flows/Existing_Patient_Call_Before_Save.flow-meta.xml`

---

## 2. Adherence__c (Agent Adherence)

### Apex Classes (2 classes)

1. **AdherenceEmailHandler.cls** - Processes CSV attachments from Calabrio to create/update Adherence records
   - Path: `force-app/main/default/classes/AdherenceEmailHandler.cls`
   - Features: CSV parsing, upsert logic, agent matching

2. **AdherenceEmailHandlerTest.cls** - Test class for AdherenceEmailHandler
   - Path: `force-app/main/default/classes/AdherenceEmailHandlerTest.cls`

### Flows (0 flows)

No flows reference Adherence__c.

---

## 3. Beth_Call_Summary__c (Beth Bot Call Summary)

### Apex Classes (0 classes)

No Apex classes reference Beth_Call_Summary__c.

### Flows (1 flow)

1. **Beth_Call_Summary.flow-meta.xml** - Processes Beth bot call summaries
   - Path: `force-app/main/default/flows/Beth_Call_Summary.flow-meta.xml`
   - Queries Beth_Call_Summary__c records with sorting by CreatedDate

---

## 4. Existing_Patient_Call__c (Existing Patient Calls)

### Apex Classes (0 classes)

No Apex classes reference Existing_Patient_Call__c.

### Flows (1 flow)

1. **Existing_Patient_Call_Before_Save.flow-meta.xml** - Record-triggered flow (before save)
   - Path: `force-app/main/default/flows/Existing_Patient_Call_Before_Save.flow-meta.xml`
   - Trigger: CreateAndUpdate on Existing_Patient_Call__c

---

## 5. FB_Lead__c (Facebook Leads)

### Apex Classes (34 classes)

1. **AutoFBLeads.cls** - Core Facebook lead processing (download, dedupe, practice assignment)
   - Path: `force-app/main/default/classes/AutoFBLeads.cls`
   - Features: API integration, ZIP matching, practice assignment logic

2. **AutoFBLeadsTest.cls** - Test class for AutoFBLeads
   - Path: `force-app/main/default/classes/AutoFBLeadsTest.cls`

3. **BatchDeleteUnusedContactsTest.cls** - References FB_Lead__c in test data
   - Path: `force-app/main/default/classes/BatchDeleteUnusedContactsTest.cls`

4. **BatchFacebookPatientMatch.cls** - Matches Facebook leads to Zeta patients
   - Path: `force-app/main/default/classes/BatchFacebookPatientMatch.cls`

5. **BatchFacebookPatientMatchTest.cls** - Test class for patient matching
   - Path: `force-app/main/default/classes/BatchFacebookPatientMatchTest.cls`

6. **BatchFBEmail.cls** - Sends email campaigns to FB leads
   - Path: `force-app/main/default/classes/BatchFBEmail.cls`

7. **BatchFBEmailTest.cls** - Test class for FB email batch
   - Path: `force-app/main/default/classes/BatchFBEmailTest.cls`

8. **BatchFBLeadsCursorTest.cls** - Test class for FB leads cursor
   - Path: `force-app/main/default/classes/BatchFBLeadsCursorTest.cls`

9. **BatchFBLeadsTest.cls** - Test class for FB leads batch processing
   - Path: `force-app/main/default/classes/BatchFBLeadsTest.cls`

10. **BatchFBLeadToZeta.cls** - Transfers FB leads to Zeta system
    - Path: `force-app/main/default/classes/BatchFBLeadToZeta.cls`

11. **BatchFBLeadToZetaTest.cls** - Test class for Zeta transfer
    - Path: `force-app/main/default/classes/BatchFBLeadToZetaTest.cls`

12. **BatchFBMessengerEmail.cls** - Sends messenger-based emails
    - Path: `force-app/main/default/classes/BatchFBMessengerEmail.cls`

13. **BatchFBMessengerEmailTest.cls** - Test class for messenger emails
    - Path: `force-app/main/default/classes/BatchFBMessengerEmailTest.cls`

14. **BatchSubmitEmailValidation.cls** - Validates FB lead emails
    - Path: `force-app/main/default/classes/BatchSubmitEmailValidation.cls`

15. **BatchSubmitEmailValidationTest.cls** - Test class for email validation
    - Path: `force-app/main/default/classes/BatchSubmitEmailValidationTest.cls`

16. **BatchTaskUpdate.cls** - Updates tasks related to FB leads
    - Path: `force-app/main/default/classes/BatchTaskUpdate.cls`

17. **BatchTaskUpdateTest.cls** - Test class for task updates
    - Path: `force-app/main/default/classes/BatchTaskUpdateTest.cls`

18. **BatchWeeklyUnscheduledFBLeads.cls** - Weekly report of unscheduled FB leads
    - Path: `force-app/main/default/classes/BatchWeeklyUnscheduledFBLeads.cls`

19. **BatchWeeklyUnscheduledFBLeadsTest.cls** - Test class for weekly report
    - Path: `force-app/main/default/classes/BatchWeeklyUnscheduledFBLeadsTest.cls`

20. **FacebookPatientMatch.cls** - Patient matching utility class
    - Path: `force-app/main/default/classes/FacebookPatientMatch.cls`

21. **FacebookPatientMatchTest.cls** - Test class for patient matching utility
    - Path: `force-app/main/default/classes/FacebookPatientMatchTest.cls`

22. **FBLeadEmail.cls** - Email notification utility for FB leads
    - Path: `force-app/main/default/classes/FBLeadEmail.cls`

23. **FBLeadEmailTest.cls** - Test class for FB lead email utility
    - Path: `force-app/main/default/classes/FBLeadEmailTest.cls`

24. **FBLeadSMS.cls** - SMS notification utility for FB leads
    - Path: `force-app/main/default/classes/FBLeadSMS.cls`

25. **FBLeadSMSTest.cls** - Test class for SMS utility
    - Path: `force-app/main/default/classes/FBLeadSMSTest.cls`

26. **FBPracticeNotifier.cls** - Notifies practices of new FB leads
    - Path: `force-app/main/default/classes/FBPracticeNotifier.cls`

27. **FBPracticeNotifierTest.cls** - Test class for practice notifier
    - Path: `force-app/main/default/classes/FBPracticeNotifierTest.cls`

28. **FixFBLeadPracticeBatch.cls** - Fixes practice assignments on FB leads
    - Path: `force-app/main/default/classes/FixFBLeadPracticeBatch.cls`

29. **FixFBLeadPracticeBatchTest.cls** - Test class for practice fix batch
    - Path: `force-app/main/default/classes/FixFBLeadPracticeBatchTest.cls`

30. **ScheduleDelUnusedRecords.cls** - Schedules deletion of unused FB lead tasks
    - Path: `force-app/main/default/classes/ScheduleDelUnusedRecords.cls`

31. **ScheduleSubmitEmailValidationTest.cls** - Test class for email validation scheduler
    - Path: `force-app/main/default/classes/ScheduleSubmitEmailValidationTest.cls`

### Flows (1 flow)

1. **Lead_Facebook_Messaging_Record_Created.flow-meta.xml** - Processes FB lead messaging records
   - Path: `force-app/main/default/flows/Lead_Facebook_Messaging_Record_Created.flow-meta.xml`
   - References FB_Lead__c object

---

## 6. OAI_Survey__c (Observe AI Survey)

### Apex Classes (3 classes)

1. **BatchCallCenterSummary.cls** - Aggregates OAI survey counts
   - Path: `force-app/main/default/classes/BatchCallCenterSummary.cls`

2. **BatchOaiSurvey.cls** - Links surveys to call summaries
   - Path: `force-app/main/default/classes/BatchOaiSurvey.cls`

3. **BatchOaiSurveyTest.cls** - Test class for OAI survey batch
   - Path: `force-app/main/default/classes/BatchOaiSurveyTest.cls`

### Flows (0 flows)

No flows reference OAI_Survey__c.

---

## 7. Quality_Monitoring__c (Quality Monitoring)

### Apex Classes (0 classes)

No Apex classes reference Quality_Monitoring__c.

### Flows (1 flow)

1. **Quality_Monitoring_Before_Save.flow-meta.xml** - Record-triggered flow (before save)
   - Path: `force-app/main/default/flows/Quality_Monitoring_Before_Save.flow-meta.xml`
   - Trigger: CreateAndUpdate on Quality_Monitoring__c
   - Looks up NVM_Call_Summary__c records

---

## 8. NVM_PCS__c (Vonage Post-Call Survey)

### Apex Classes (3 classes)

1. **BatchCallCenterSummary.cls** - Aggregates PCS counts
   - Path: `force-app/main/default/classes/BatchCallCenterSummary.cls`

2. **BatchPCS.cls** - Links PCS records to call summaries via Call_Object_Identifier__c
   - Path: `force-app/main/default/classes/BatchPCS.cls`

3. **BatchPCSTest.cls** - Test class for PCS batch
   - Path: `force-app/main/default/classes/BatchPCSTest.cls`

### Flows (1 flow)

1. **NVM_PCS_After_Save.flow-meta.xml** - Record-triggered flow (after save)
   - Path: `force-app/main/default/flows/NVM_PCS_After_Save.flow-meta.xml`
   - Trigger: CreateAndUpdate on NVM_PCS__c
   - Queries NVMStatsSF__NVM_Call_Summary__c

---

## 9. Lead (Standard Object)

### Note
The standard Lead object has extensive custom fields but was searched separately. The Lead object metadata is located at:
- `force-app/main/default/objects/Lead/`

Many Apex classes and Flows reference the Lead object throughout the codebase. The FB_Lead__c custom object has relationships to the standard Lead object.

---

## Statistics Summary

| Object | Apex Classes | Flows | Total References |
|--------|--------------|-------|------------------|
| NVMStatsSF__NVM_Call_Summary__c | 24 | 5 | 29 |
| Adherence__c | 2 | 0 | 2 |
| Beth_Call_Summary__c | 0 | 1 | 1 |
| Existing_Patient_Call__c | 0 | 1 | 1 |
| FB_Lead__c | 34 | 1 | 35 |
| OAI_Survey__c | 3 | 0 | 3 |
| Quality_Monitoring__c | 0 | 1 | 1 |
| NVM_PCS__c | 3 | 1 | 4 |
| **Total** | **66** | **10** | **76** |

---

## Key Integration Points

### Call Center Operations
- **NVM_Call_Summary__c** is the central object for call tracking
- Links to NVM_PCS__c for post-call surveys
- Links to OAI_Survey__c for Observe AI surveys
- Links to Quality_Monitoring__c for QA tracking
- Links to Existing_Patient_Call__c for existing patient tracking

### Facebook Lead Management
- **FB_Lead__c** is extensively integrated with practice notifications
- Email and SMS campaigns are managed through batch classes
- Patient matching with Zeta system
- Weekly reporting for unscheduled leads

### Quality & Compliance
- **Adherence__c** tracks agent adherence via Calabrio integration
- **Quality_Monitoring__c** has three record types (ADIC, Observe_AI, QM_Points)
- Both link back to call summaries for comprehensive QA

---

## Recommendations

1. **Testing Coverage**: Ensure all referenced classes have adequate test coverage (target: 75%+)
2. **Documentation**: Document integration points between objects
3. **Performance**: Monitor batch job execution times for large data volumes
4. **Error Handling**: Review error handling in batch classes, especially for API integrations
5. **Deprecation**: Consider deprecating unused relationships or fields
6. **Flow Optimization**: Review flow bulkification and governor limits

---

End of Report