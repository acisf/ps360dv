@istest

public class RepairsSendEmailTest {

    @isTest
    public static void testSendEmail(){
    
        Account newAcc = new Account();
        newAcc.name='test';
        insert newAcc;
        
        List<Contact> con=new List<Contact>();
        Integer i = 1;
        for(i=1; i<3; i++){
            Contact cn = new Contact();
            cn.AccountId = newAcc.id;
            cn.FirstName = 'ABC';
            cn.lastname='Testing' + i;
            cn.email='test'+i+'@test.com';
            con.add(cn);
        }
        insert con;
        
        List<Case> cases = new list<Case>();
        For(i=0; i<2 ; i++){
            Case c = new Case();
            c.AccountId = newAcc.id;
            if(i == 0)
                c.ContactId = con[i].id;
            c.SuppliedEmail = con[i].Email;
            cases.add(c);
        }
        insert cases;
        
        List<Id> caseid = new List<Id>();
        for(i=0; i<2; i++)
            caseid.add(cases[i].id);
        RepairsSendEmail.repairEmail(caseid);
    }
}