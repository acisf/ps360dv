public class VFLoginFlowController {

    public PageReference FinishLoginFlowStartUrl() {
        //do stuff
        
        //finish the login flow and send you to the startUrl (account page in this case)
        return Auth.SessionManagement.finishLoginFlow('/lightning/page/home');
    }


    public PageReference FinishLoginFlowHome() {
        //do stuff
        
        //finish the login flow and send you the default homepage
        return Auth.SessionManagement.finishLoginFlow();
    }
}