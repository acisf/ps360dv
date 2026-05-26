@IsTest
private class ViewSurveyController_Test{

	@TestSetup
	static void makeData(){
		User u = SurveyTestingUtil.createNewAdminPermissionSetUser();       
	}

	@IsTest
	private static void testViewSurveyController_constructor3() {
		User u = [SELECT Id FROM User WHERE Username LIKE '%@testorg.com' LIMIT 1];        
		System.runAs(u){
			SurveyTestingUtil tu = new SurveyTestingUtil();
            /*MN*/
            Account a = new Account(Name = 'Test Acc');
            insert a;
            /*MN*/
			Contact c = new Contact();            
			c.FirstName = 'John';
			c.LastName = 'Doe';
            c.AccountId = a.id;		//MN
			insert c;
            
            /*MN*/             
            Case cs = new Case();
            cs.ContactId = c.id;
            cs.Subject = 'Test Case1';
            cs.Description = 'Test Case1';
            cs.Team__c = 'IT';
            cs.Category__c = 'Something else';
            cs.GUID__c = '1111111111';
            cs.OwnerId = u.id;
            insert cs;
            /*MN*/

			Test.startTest();

			Test.setCurrentPage(Page.TakeSurvey);

			Apexpages.currentPage().getParameters().put('id',tu.surveyId);
			Apexpages.currentPage().getParameters().put('cId',c.Id);
            Apexpages.currentPage().getParameters().put('guid',cs.GUID__c);		//MN
            Apexpages.currentPage().getParameters().put('caseowner',cs.OwnerId);		//MN01
			Apexpages.Standardcontroller std = new ApexPages.StandardController(tu.survey);
			ViewShareSurveyComponentController vscc = new ViewShareSurveyComponentController();
			ViewSurveyController vsc = new ViewSurveyController(vscc);
			vsc.init();

			System.assert(vsc.allQuestionsSize == 4);
			System.assert(tu.surveyId != null);

			for (SFQuestion q : vsc.allQuestions)
			{
				q.selectedOption = String.valueof(2);
				q.choices = String.valueof(2);
				q.selectedOptions = new List<String>();
				q.selectedOptions.add(String.valueof(2));
				vsc.submitResults();
			}
			System.assertEquals(true, vsc.ThankYouRendered);

			//Run again to hit an exception for code coverage
			//There is no return value as this is void method
			List<SurveyTaker__c> check = [SELECT Contact__c, Survey__c, Case__c, User__c FROM SurveyTaker__c WHERE Survey__c=:tu.surveyId and
			((Contact__c != null and Contact__c=:c.Id))];
			System.debug('Check:' + check);

			vsc.init();
			for (SFQuestion q : vsc.allQuestions)
			{
				q.selectedOption = String.valueof(2);
				q.choices = String.valueof(2);
				q.selectedOptions = new List<String>();
				q.selectedOptions.add(String.valueof(2));
				vsc.submitResults();
			}

			check = [SELECT Contact__c, Survey__c, Case__c, User__c FROM SurveyTaker__c WHERE Survey__c=:tu.surveyId and
			((Contact__c != null and Contact__c=:c.Id))];
			System.debug('Check:' + check);            
			Test.stopTest();
		}

		//test something
	}

	/* @IsTest
	private static void testgetResponses(){
		User u = [SELECT Id FROM User WHERE Username LIKE '%@testorg.com' LIMIT 1];
		System.runAs(u){
			SurveyTestingUtil tu = new SurveyTestingUtil();
			Apexpages.currentPage().getParameters().put('id',tu.surveyId);
			Apexpages.Standardcontroller stc = new ApexPages.StandardController(tu.survey);
			ViewSurveyController vsc = new ViewSurveyController(stc);
			vsc.init();
			List<String> responses = vsc.getResponses();
			System.debug(responses);
		}

	} */

	@IsTest
	private static void testViewSurveyController_constructor2() {
		User u = [SELECT Id FROM User WHERE Username LIKE '%@testorg.com' LIMIT 1];
        
		System.runAs(u){
			SurveyTestingUtil tu = new SurveyTestingUtil();
            /*MN*/
            Account a = new Account(Name = 'Test Acc2');
            insert a;
            Contact con = new Contact(FirstName='Test',LastName='Contact2',Email='test.contact2@example.com',accountId=a.id);
            insert con;
            Case cs = new Case();
            cs.ContactId = con.id;
            cs.Subject = 'Test Case2';
            cs.Description = 'Test Case2';
            cs.Team__c = 'IT';
            cs.Category__c = 'Something else';
            cs.GUID__c = '22222222222';
            insert cs;
            /*MN*/
			Test.setCurrentPage(Page.TakeSurvey);
			Apexpages.currentPage().getParameters().put('id',tu.surveyId);
            Apexpages.currentPage().getParameters().put('guid',cs.GUID__c);		//MN

			ViewShareSurveyComponentController vscc = new ViewShareSurveyComponentController();
			ViewSurveyController vsc = new ViewSurveyController(vscc);
			vsc.init();
			System.assert(vsc.allQuestionsSize == 4);
			System.assert(tu.surveyId != null);

			vsc.submitResults();
			for (SFQuestion q : vsc.allQuestions)
			{
				q.selectedOption = String.valueof(2);
				q.choices = String.valueof(2);
				q.selectedOptions = new List<String>();
				q.selectedOptions.add(String.valueof(2));
				vsc.submitResults();
			}
			System.assertEquals(true, vsc.ThankYouRendered);

		}
		//test something
	}

	@IsTest
	private static void testViewSurveyController() {
		User u = [SELECT Id FROM User WHERE Username LIKE '%@testorg.com' LIMIT 1];
        
		System.runAs(u){
			Test.startTest();
			SurveyTestingUtil tu = new SurveyTestingUtil();
            /*MN*/
            Account a = new Account(Name = 'Test Acc3');
            insert a;
            Contact con = new Contact(FirstName='Test',LastName='Contact3',Email='test.contact3@example.com',accountId=a.id);
            insert con;
            Case cs = new Case();
            cs.ContactId = con.id;
            cs.Subject = 'Test Case3';
            cs.Description = 'Test Case3';
            cs.Team__c = 'IT';
            cs.Category__c = 'Something else';
            cs.GUID__c = '333333333333';
            insert cs;
            /*MN*/
			Apexpages.currentPage().getParameters().put('id',tu.surveyId);
            Apexpages.currentPage().getParameters().put('guid',cs.GUID__c);		//MN
			Apexpages.Standardcontroller stc = new ApexPages.StandardController(tu.survey);
			ViewSurveyController vsc = new ViewSurveyController(stc);
			vsc.init();
			System.assert(vsc.allQuestionsSize == 4);
			System.assert(tu.surveyId != null);

			vsc.submitResults();
			for (SFQuestion q : vsc.allQuestions)
			{
				q.selectedOption = String.valueof(2);
				q.choices = String.valueof(2);
				q.selectedOptions = new List<String>();
				q.selectedOptions.add(String.valueof(2));
				vsc.submitResults();
			}
			Test.stopTest();
			System.assertEquals(true, vsc.ThankYouRendered);
		}

		//test something
	}

	@IsTest
	private static void testrefreshQuestionList() {
		User u = [SELECT Id FROM User WHERE Username LIKE '%@testorg.com' LIMIT 1];
        //Case cs = [Select Id from Case where createddate = today limit 1];		//MN
		System.runAs(u){
			Test.startTest();

			SurveyTestingUtil tu = new SurveyTestingUtil();
			Apexpages.currentPage().getParameters().put('id',tu.surveyId);
            //Apexpages.currentPage().getParameters().put('guid',cs.GUID__c);		//MN
			Apexpages.Standardcontroller stc = new ApexPages.StandardController(tu.survey);
			ViewSurveyController vsc = new ViewSurveyController(stc);
			system.assertEquals(null, vsc.refreshQuestionList() );
            vsc.onLoad();							//MN
            Test.stopTest();
		}
	}

}