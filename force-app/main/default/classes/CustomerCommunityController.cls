public class CustomerCommunityController {
    
    @AuraEnabled
    public static User getLoggedInUser(){
        return [Select Id, User_PracticeID__c from User where Id =: UserInfo.getUserId() Limit 1];
    }

}