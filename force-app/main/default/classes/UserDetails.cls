public class UserDetails {
    
    @InvocableMethod (label='UserDetails')
    public static List<List<User>> getUserDetails(List<List<Id>> ids){
        List<User> unames = new List<User>();
        for(User u: [Select id, Name from User where id in :ids[0] order by Name]){
            unames.add(u);
        }
        return (new List<List<User>>{unames});
    }

}