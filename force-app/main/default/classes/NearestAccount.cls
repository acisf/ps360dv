public class NearestAccount  implements Comparable{
        @AuraEnabled
        public Id recordid;
        @AuraEnabled
        public String nameurl;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String distancetext;    
        @AuraEnabled
        public Double distancevalue;
         @AuraEnabled
        public String drivingtime;
         @AuraEnabled
        public String servicecode;
         @AuraEnabled
        public String practicetype;
         @AuraEnabled
        public String insaccepted;
    
    
    public Integer compareTo(Object other) {
        NearestAccount o = (NearestAccount) other;
        if (this.distancevalue < o.distancevalue) return -1;
        if (this.distancevalue > o.distancevalue) return 1;
        return 0;
    }
    }