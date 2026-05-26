@IsTest
private class NearestAccountTest {

    @IsTest
    static void testFieldAssignment() {
        NearestAccount na  = new NearestAccount();
        na.recordid        = Id.valueOf('001000000000001AAA');
        na.nameurl         = 'https://example.com/account/001000000000001AAA';
        na.Name            = 'Test Account';
        na.distancetext    = '5 miles';
        na.distancevalue   = 5.0;
        na.drivingtime     = '10 mins';
        na.servicecode     = 'SC123';
        na.practicetype    = 'Dental';
        na.insaccepted     = 'Yes';

        Assert.areEqual(Id.valueOf('001000000000001AAA'), na.recordid);
        Assert.areEqual('https://example.com/account/001000000000001AAA', na.nameurl);
        Assert.areEqual('Test Account', na.Name);
        Assert.areEqual('5 miles', na.distancetext);
        Assert.areEqual(5.0, na.distancevalue);
        Assert.areEqual('10 mins', na.drivingtime);
        Assert.areEqual('SC123', na.servicecode);
        Assert.areEqual('Dental', na.practicetype);
        Assert.areEqual('Yes', na.insaccepted);
    }

    @IsTest
    static void testCompareTo() {
        NearestAccount closer  = new NearestAccount();
        closer.distancevalue   = 5.0;

        NearestAccount farther = new NearestAccount();
        farther.distancevalue  = 10.0;

        NearestAccount equal   = new NearestAccount();
        equal.distancevalue    = 5.0;

        Assert.areEqual(-1, closer.compareTo(farther));
        Assert.areEqual(1,  farther.compareTo(closer));
        Assert.areEqual(0,  closer.compareTo(equal));
    }

    @IsTest
    static void testSort() {
        NearestAccount na1 = new NearestAccount();
        na1.Name           = 'Far Practice';
        na1.distancevalue  = 50.0;

        NearestAccount na2 = new NearestAccount();
        na2.Name           = 'Near Practice';
        na2.distancevalue  = 5.0;

        List<NearestAccount> lst = new List<NearestAccount>{ na1, na2 };
        lst.sort();

        Assert.areEqual('Near Practice', lst[0].Name);
        Assert.areEqual('Far Practice',  lst[1].Name);
    }
}