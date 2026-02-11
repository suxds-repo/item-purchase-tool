import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getAccount from '@salesforce/apex/ItemPurchaseController.getAccount';

export default class ItemPurchaseApp extends LightningElement {

    @track accountId;
    @track account;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {

        if (pageRef && pageRef.state?.c__accountId) {
            this.accountId = pageRef.state.c__accountId;
        }
    }

    @wire(getAccount, { accountId: '$accountId' })
    wiredAccount({ error, data }) {

        if (data) {
            this.account = data;
        }

        if (error) {
            console.error(error);
        }
    }
}
