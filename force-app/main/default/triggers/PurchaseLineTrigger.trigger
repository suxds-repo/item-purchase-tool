trigger PurchaseLineTrigger on PurchaseLine__c (
    after insert,
    after update,
    after delete,
    after undelete
) {

    Set<Id> purchaseIds = new Set<Id>();

    // Insert / Update / Undelete
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (PurchaseLine__c pl : Trigger.new) {
            if (pl.PurchaseId__c != null) {
                purchaseIds.add(pl.PurchaseId__c);
            }
        }
    }

    // Delete
    if (Trigger.isDelete) {
        for (PurchaseLine__c pl : Trigger.old) {
            if (pl.PurchaseId__c != null) {
                purchaseIds.add(pl.PurchaseId__c);
            }
        }
    }

    if (purchaseIds.isEmpty()) {
        return;
    }

    // Aggregate query
    List<AggregateResult> results = [
        SELECT
            PurchaseId__c purchaseId,
            COUNT(Amount__c) totalItems,
            SUM(LineTotal__c) grandTotal
        FROM PurchaseLine__c
        WHERE PurchaseId__c IN :purchaseIds
        GROUP BY PurchaseId__c
    ];

    Map<Id, Purchase__c> purchasesToUpdate = new Map<Id, Purchase__c>();

    for (AggregateResult ar : results) {

        Id purchaseId = (Id) ar.get('purchaseId');
        Integer totalItems = (Integer) ar.get('totalItems');
        Decimal grandTotal = (Decimal) ar.get('grandTotal');

        purchasesToUpdate.put(
            purchaseId,
            new Purchase__c(
                Id = purchaseId,
                TotalItems__c = totalItems,
                GrandTotal__c = grandTotal
            )
        );
    }

    // For purchases with 0 lines (after delete)
    for (Id pid : purchaseIds) {
        if (!purchasesToUpdate.containsKey(pid)) {
            purchasesToUpdate.put(
                pid,
                new Purchase__c(
                    Id = pid,
                    TotalItems__c = 0,
                    GrandTotal__c = 0
                )
            );
        }
    }

    update purchasesToUpdate.values();
}
