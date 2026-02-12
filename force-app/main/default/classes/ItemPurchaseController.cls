public with sharing class ItemPurchaseController {

    @AuraEnabled(cacheable=true)
    public static Account getAccount(Id accountId) {

        if (accountId == null) {
            return null;
        }

        return [
            SELECT Id,
                   Name,
                   AccountNumber,
                   Industry
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(
        String family,
        String type,
        String searchKey
    ) {

        String query =
            'SELECT Id, Name, Price__c, Image__c, Family__c, Type__c, Description__c ' +
            'FROM Item__c WHERE Id != null ';

        if (family != null && family != '') {
            query += ' AND Family__c = :family';
        }

        if (type != null && type != '') {
            query += ' AND Type__c = :type';
        }

        if (searchKey != null && searchKey != '') {

            String search = '%' + searchKey + '%';

            query +=
                ' AND (Name LIKE :search OR Description__c LIKE :search)';
        }

        query += ' ORDER BY Name LIMIT 100';

        return Database.query(query);
    }
    

     
    @AuraEnabled(cacheable=true)
    public static List<String> getTypePicklistValues() {
        Schema.DescribeFieldResult fieldResult = Item__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> values = new List<String>();
        for(Schema.PicklistEntry f : ple){
            values.add(f.getValue());
        }
        return values;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<String> getFamilyPicklistValues() {
        Schema.DescribeFieldResult fieldResult = Item__c.Family__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> values = new List<String>();
        for(Schema.PicklistEntry f : ple){
            values.add(f.getValue());
        }
        return values;
    }

    @AuraEnabled
    public static Item__c createItem(String name, String description, String family, String type, Decimal price) {
        String imageUrl = UnsplashService.getImageUrl(name);

        Item__c newItem = new Item__c(
            Name = name,
            Description__c = description,
            Family__c = family,
            Type__c = type,
            Price__c = price,
            Image__c = imageUrl
        );
        insert newItem;
        return newItem;
    }


    @AuraEnabled
    public static Id checkoutCart(Id accountId, List<Id> itemIds) {

        if (accountId == null || itemIds.isEmpty()) {
            throw new AuraHandledException('Invalid cart data');
        }

        // Create Purchase
        Purchase__c purchase = new Purchase__c(
            ClientId__c = accountId
        );

        insert purchase;


        // Get items
        List<Item__c> items = [
            SELECT Id, Price__c
            FROM Item__c
            WHERE Id IN :itemIds
        ];


        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();

        for (Item__c item : items) {

            lines.add(new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = item.Id,
                Amount__c = 1,
                UnitCost__c = item.Price__c
            ));
        }

        insert lines;

        return purchase.Id;
    }

}

