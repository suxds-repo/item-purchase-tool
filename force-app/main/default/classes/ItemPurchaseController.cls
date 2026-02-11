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
}
