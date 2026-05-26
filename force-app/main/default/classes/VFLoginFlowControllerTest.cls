@isTest
public class VFLoginFlowControllerTest {

    @isTest
    static void testFinishLoginFlowStartUrl() {
        Test.startTest();
        // Instantiate the VFLoginFlowController
        VFLoginFlowController controller = new VFLoginFlowController();
        // Call the method under test
        PageReference result = controller.FinishLoginFlowStartUrl();
        // Verify that the result is not null
        System.assertNotEquals(null, result);
        // Verify that the URL returned is as expected
        System.assertEquals('/lightning/page/home', result.getUrl());
        Test.stopTest();
    }

    @isTest
    static void testFinishLoginFlowHome() {
        Test.startTest();
        // Instantiate the VFLoginFlowController
        VFLoginFlowController controller = new VFLoginFlowController();
        // Call the method under test
        PageReference result = controller.FinishLoginFlowHome();
        // Verify that the result is not null
        System.assertNotEquals(null, result);
        // Verify that the URL returned is the default homepage
        Test.stopTest();
    }
}