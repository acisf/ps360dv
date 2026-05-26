@IsTest(SeeAllData=true)
public class ConnectApiMock implements System.StubProvider {
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        System.debug('Mock method called: ' + stubbedMethodName);

        // Handle postFeedElement specifically
        if (stubbedMethodName == 'postFeedElement') {
            System.debug('Intercepted postFeedElement');
            return 'mockFeedElementId'; // Simulate a successful post by returning a mock ID
        }

        // Default return
        return null;
    }
}