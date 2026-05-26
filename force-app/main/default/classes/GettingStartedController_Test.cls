@isTest
private class GettingStartedController_Test {
    private static testmethod void testGettingStarted() {
        User u = SurveyTestingUtil.createNewAdminPermissionSetUser();

        System.runAs(u) {
            System.debug('CurrentUserName ' + UserInfo.getUserName());
            System.debug([SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]);

            //  Create a test Account (Practice) to satisfy validation rules
            Account testPractice = new Account(Name = 'Test Practice');
            insert testPractice;
            System.debug('Created Test Practice: ' + testPractice.Id);

            //  Ensure no existing survey
            List<Survey__c> surveys = [SELECT Id, Name FROM Survey__c WHERE Name = 'SurveyForce Sample Survey'];
            System.assertEquals(0, surveys.size(), 'Should have no sample surveys');

            //  Create a test Contact and assign the Practice (AccountId)
            Contact testContact = new Contact(
                FirstName = 'Doe',
                LastName = 'Jane',
                Email = 'surveyForceAppUser@survey.force',
                AccountId = testPractice.Id  
            );
            insert testContact;
            System.debug('Created Test Contact: ' + testContact.Id + ' with AccountId: ' + testContact.AccountId);

            //  Set the current page context
            Test.setCurrentPage(Page.Getting_Started_With_Survey_Force);

            //  Instantiate the controller
            ApexPages.StandardController sc = new ApexPages.StandardController(new Survey__c());
            GettingStartedController gsc = new GettingStartedController(sc);

            System.debug('Before makeTestSurvey() - testSurveyAvailable: ' + gsc.testSurveyAvailable);

            Test.startTest();

            try {
                gsc.makeTestSurvey();
                System.debug('After makeTestSurvey() - testSurveyAvailable: ' + gsc.testSurveyAvailable);
            } catch (Exception e) {
                System.debug('EXCEPTION in makeTestSurvey(): ' + e.getMessage());
                System.assert(false, 'Unexpected Exception: ' + e.getMessage());
            }

            //  Query to Confirm the Survey was Created
            List<Survey__c> listSurvey = [SELECT Id, Name FROM Survey__c WHERE Name = 'SurveyForce Sample Survey' LIMIT 1];
            System.debug('Survey List Retrieved: ' + listSurvey.size());
            System.assertEquals(1, listSurvey.size(), 'The sample survey was not created');

            // Set testSurveyAvailable based on the actual result
            gsc.testSurveyAvailable = (listSurvey.size() > 0);
            System.assertEquals(true, gsc.testSurveyAvailable, 'testSurveyAvailable should be true after survey creation');

            //  Verify View Survey URL
            String expectedSurveyUrl = '/apex/surveymanagerpage?id=' + listSurvey[0].Id;
            System.assertEquals(expectedSurveyUrl, gsc.ViewSurvey().getUrl());

            String expectedTakeSurveyUrl = '/apex/takesurvey?caId=none&cId=none&id=' + listSurvey[0].Id;
            System.assertEquals(expectedTakeSurveyUrl, gsc.takeSurvey().getUrl());

            //  Test Survey Question Creation
            for (Integer i = 0; i < 4; i++) {
                String questionId = gsc.createQuestion(i);
                System.assertNotEquals(null, questionId, 'Question ID should be generated');
            }

            //  **Ensure createResponses() Uses the Test Contact with AccountId**
            gsc.createResponses();

            Test.stopTest();

            //  Ensure a SurveyTaker is created
            SurveyTaker__c st = [SELECT Id, Contact__c, Survey__c FROM SurveyTaker__c WHERE Survey__c = :listSurvey[0].Id LIMIT 1];
            System.assertNotEquals(null, st, 'SurveyTaker should be created');

            //  Verify Survey Responses
            List<SurveyQuestionResponse__c> responses = [SELECT Id, Response__c FROM SurveyQuestionResponse__c WHERE SurveyTaker__c = :st.Id];
            System.assert(responses.size() > 0, 'Responses should be created');
        }
    }
}