@IsTest
public class ItemPurchaseControllerTest {

    // =========================
    // TEST SETUP
    // =========================
    @TestSetup
    static void setupData() {

        // Account
        insert new Account(Name = 'Test Account');

        // Manager User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        insert new User(
            FirstName='Test',
            LastName='Manager',
            Email='testmanager@test.com',
            Username='testmanager' + System.currentTimeMillis() + '@test.com',
            Alias='tman',
            TimeZoneSidKey='Europe/London',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=p.Id,
            IsManager__c=true
        );

        // Default Item
        insert new Item__c(
            Name='Test Item',
            Description__c='Test Desc',
            Family__c='A',
            Type__c='Food',
            Price__c=100
        );
    }

    // =========================
    // TEST: isCurrentUserManager
    // =========================
    @IsTest
    static void testIsManagerAndNotManager() {

        User manager = [SELECT Id FROM User WHERE IsManager__c = true LIMIT 1];
        System.runAs(manager) {
            System.assert(ItemPurchaseController.isCurrentUserManager(), 'Manager should return true');
        }

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User normalUser = new User(
            FirstName='Normal', LastName='User',
            Email='normaluser@test.com',
            Username='normaluser' + System.currentTimeMillis() + '@test.com',
            Alias='nuser', TimeZoneSidKey='Europe/London',
            LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US', ProfileId=p.Id,
            IsManager__c=false
        );
        insert normalUser;

        System.runAs(normalUser) {
            System.assert(!ItemPurchaseController.isCurrentUserManager(), 'Non-manager should return false');
        }
    }

    // =========================
    // TEST: createItem
    // =========================
    @IsTest
    static void testCreateItemAndRequiredFields() {

        User manager = [SELECT Id FROM User WHERE IsManager__c = true LIMIT 1];
        System.runAs(manager) {

            // Valid item creation
            Test.startTest();
            Item__c validItem = ItemPurchaseController.createItem('Apple', 'Red Apple', 'A', 'Food', 50);
            Test.stopTest();

            System.assertNotEquals(null, validItem.Id, 'Item Id should be generated');
            System.assertEquals('Apple', validItem.Name);
            System.assertEquals(50, validItem.Price__c);

            // Test missing required fields using parameterized approach
            List<Map<String, Object>> testCases = new List<Map<String,Object>>{
                new Map<String,Object>{'name'=>'','desc'=>'desc','family'=>'A','type'=>'Food','price'=>10},
                new Map<String,Object>{'name'=>'Item','desc'=>'desc','family'=>'','type'=>'Food','price'=>10},
                new Map<String,Object>{'name'=>'Item','desc'=>'desc','family'=>'A','type'=>'','price'=>10},
                new Map<String,Object>{'name'=>'Item','desc'=>'desc','family'=>'A','type'=>'Food','price'=>0}
            };

            for (Map<String,Object> tc : testCases) {
                Boolean exceptionThrown = false;
                try {
                    ItemPurchaseController.createItem(
                        (String)tc.get('name'),
                        (String)tc.get('desc'),
                        (String)tc.get('family'),
                        (String)tc.get('type'),
                        (Decimal)tc.get('price')
                    );
                } catch (AuraHandledException e) {
                    exceptionThrown = true;
                }
                System.assert(exceptionThrown, 'Expected exception for invalid input: ' + tc);
            }
        }
    }

    // =========================
    // TEST: checkout is valid
    // =========================

    @IsTest
    static void testCheckoutValidCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        Test.startTest();
        Id purchaseId = ItemPurchaseController.checkoutCart(acc.Id, new List<Id>{ item.Id });
        Test.stopTest();

        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(1, p.TotalItems__c);
        System.assertEquals(item.Price__c, p.GrandTotal__c);

        List<PurchaseLine__c> lines = [SELECT Id FROM PurchaseLine__c WHERE PurchaseId__c = :purchaseId];
        System.assertEquals(1, lines.size());
    }

    @IsTest
    static void testCheckoutEmptyCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ItemPurchaseController.checkoutCart(acc.Id, new List<Id>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected AuraHandledException when cart is empty');
    }

    @IsTest
    static void testCheckoutWithNullAccount() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ItemPurchaseController.checkoutCart(null, new List<Id>{ '001000000000001' });
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for null account');
    }

    @IsTest
    static void testCheckoutWithInvalidItemId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // random ID
        Id fakeItemId = 'a0B000000000001'; 
        
        Test.startTest();
        Id purchaseId = ItemPurchaseController.checkoutCart(acc.Id, new List<Id>{ fakeItemId });
        Test.stopTest();
        
        // check if Purchase created, but PurchaseLine empty
        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(null, p.TotalItems__c, 'No items should be counted for invalid Item Id');
        System.assertEquals(null, p.GrandTotal__c, 'GrandTotal should be 0 for invalid Item Id');

        List<PurchaseLine__c> lines = [SELECT Id FROM PurchaseLine__c WHERE PurchaseId__c = :purchaseId];
        System.assertEquals(0, lines.size(), 'No PurchaseLine should be created');
    }


    // =========================
    // TEST: Trigger on delete
    // =========================
    @IsTest
    static void testTriggerOnDelete() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        Id purchaseId = ItemPurchaseController.checkoutCart(acc.Id, new List<Id>{ item.Id });
        PurchaseLine__c line = [SELECT Id FROM PurchaseLine__c LIMIT 1];

        Test.startTest();
        delete line;
        Test.stopTest();

        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(0, p.TotalItems__c);
        System.assertEquals(0, p.GrandTotal__c);
    }


    @IsTest
    static void testTriggerUpdateAndUndelete() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        Id purchaseId = ItemPurchaseController.checkoutCart(acc.Id, new List<Id>{ item.Id });
        PurchaseLine__c line = [SELECT Id, Amount__c FROM PurchaseLine__c LIMIT 1];

        Test.startTest();
        // Update
        line.Amount__c = 2;
        update line;

        // Undelete
        delete line;
        undelete line;
        Test.stopTest();

        Purchase__c p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assert(p.TotalItems__c > 0, 'TotalItems should reflect updated and undeleted line');
    }

    // =========================
    // TEST: Filter
    // =========================
    
    @IsTest
    static void testGetItemsWithFilter() {
        Item__c item = [SELECT Id, Name FROM Item__c LIMIT 1];

        List<Item__c> result = ItemPurchaseController.getItems('A', 'Food', 'Test');
        System.assert(result.size() > 0, 'Should return items matching filter');
    }

}
