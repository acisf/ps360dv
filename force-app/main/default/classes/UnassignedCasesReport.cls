public class UnassignedCasesReport {
    
    public static void sendUnassignedCasesReport(String queueName){
        String str = queueName;
        Id grpId;
        Set<Id> grpMemIds = new Set<Id>();       
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage mail;
        List<String> toAddr = new List<String>();
        List<String> bccAddr = new List<String>();
        String strSubject = '';
        String strHTML = '';
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'appteam@affordablecare.com'];  
        
        Group grp = getGroupDetails(str);
        grpId = grp.Id;
        
        grpMemIds = getGroupMembers(grpMemIds,grpId);
        toAddr = getGroupMembersEmailAddress(toAddr,grpMemIds);  
        bccAddr.add('douglas.vann@affordablecare.com');
        bccAddr.add('madhuri.nandula@affordablecare.com');        
        
        mail = new Messaging.SingleEmailMessage();
        mail = composeEmail(mail, strHtml, grpId,strSubject, str);        
        
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        mail.setBCCSender(false);
        mail.setToAddresses(toAddr);  
        mail.setBCcAddresses(bccAddr);
        allmsg.add(mail);
        
        Messaging.sendEmail(allmsg,false);       
    }

    public static Group getGroupDetails(String str){
        return [Select id, name from group where type = 'queue' 
                and name Like :str limit 1];
    }
    
    public static Set<Id> getGroupMembers(Set<Id> grpMemIds, Id grpId){
        For(GroupMember mem: [Select GroupId, UserOrGroupId from GroupMember 
                              where GroupId = :grpId]){                              
            grpMemIds.add(mem.UserOrGroupId);  
        }
        
        //To get group members if the queue has public group or roles as members instead of users
        Id memId = new List<Id> (grpMemIds).get(0);
        if(String.ValueOf(memId).startsWith('00G')){            
                List<Group> lstGrp = [Select id, name, relatedId, type from Group
                                      where id in :grpMemIds];
                if(lstGrp[0].type.startsWith('Role')){                   
                    grpMemIds.clear();
                    for(Group g: lstGrp){
                        grpMemIds.add(g.RelatedId);    
                    }
                }
                else{
                    List<GroupMember> lstGrpM= [Select UserOrGroupId from GroupMember where groupId = :memId];
                    if(lstGrpM.size() > 0){
                        grpMemIds.clear();
                        for(GroupMember grpm: lstGrpM){
                            grpMemIds.add(grpm.UserOrGroupId);
                        }
                    }
                    List<Group> lstRoleGrp = [Select id, name, relatedId, type from Group
                                              where id in :grpMemIds];
                    if(lstRoleGrp.size() > 0){
                        if(lstRoleGrp[0].type.startsWith('Role')){                        
                            grpMemIds.clear();
                            for(Group g: lstRoleGrp){
                                grpMemIds.add(g.RelatedId);    
                            }
                        }
                    }
                }
            }               
       
        return grpMemIds;
    }
    
    public static List<String> getGroupMembersEmailAddress(List<String> toAddr, Set<Id>grpMemIds){
        if(grpMemIds.size() > 0){
            For(User u: [Select email from user where id in :grpMemIds
                         Or userRoleId in :grpMemIds]){
                toAddr.add(u.email);            
            }
        }
        return toAddr;
    }

    public static Messaging.SingleEmailMessage composeEmail(Messaging.SingleEmailMessage mail, String strHtml, Id grpId,String strSubject, String queuename){
        List<Case> lstCases = [Select Id, casenumber, Subject, Createddate, ownerId from case 
                               where ownerid = :grpId
                               and isClosed = false
                               and recordtype.Name = 'ACE Service'
                               order by createddate desc];  
             
        strSubject = 'Warning: There are '+ lstCases.size() + ' unassigned cases in ' + queuename + ' queue';
        strHTML = 'Warning: There are '+ lstCases.size() + ' unassigned cases in ' + queuename + ' queue. Please review and take ownership of unassigned cases now.' + '<br></br>';
        strHTML += '<table border="1" style="border-collapse: collapse">' +
                   '<caption>Unassigned Cases</caption> ' +
                   '<tr><th style="padding: 15px">Case Number</th><th style="padding: 15px">Subject</th><th style="padding: 15px">Date Opened</th></tr>';
        
        mail.optoutpolicy='FILTER';
        mail.setUseSignature(false);
        mail.setSubject(strSubject);
        
        For(Case cases: lstCases){                                        
            strHTML += '<tr><td style="padding: 15px"><a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + cases.id + '">' + cases.CaseNumber + '</a>'+
                       '</td><td style="padding: 15px">' + cases.Subject + 
                       '</td><td style="padding: 15px">' + cases.createddate + '</td></tr>';                           
            mail.setHtmlBody(strHTML);
            mail.setPlainTextBody(strHTML.stripHtmlTags());                                                        
        }       
        
        return mail;
    }
}