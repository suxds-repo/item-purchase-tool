public with sharing class TestConnection {
    @AuraEnabled
    public static String ping() {
        return 'OK';
    }
}