import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';

import getAccount from '@salesforce/apex/ItemPurchaseController.getAccount';

export default class ItemPurchaseApp extends LightningElement {

    @track accountId;
    @track account;
    @track items = [];
    familyOptions = [
        { label: '--All--', value: '' },
        { label: 'A', value: 'A' },
        { label: 'B', value: 'B' },
        { label: 'C', value: 'C' },
        { label: 'D', value: 'D' },
    ];

    typeOptions = [
        { label: '--All--', value: '' },
        { label: 'Food', value: 'Food' },
        { label: 'Tech', value: 'Tech' },
        { label: 'Office', value: 'Office' },
        { label: 'Other', value: 'Other' },
    ];

    @track familyFilter = null;
    @track typeFilter = null;
    @track searchKey = null;

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

    @wire(getItems, {
        family: '$familyFilter',
        type: '$typeFilter',
        searchKey: '$searchKey'
    })
    wiredItems({ error, data }) {

        if (data) {
            this.items = data;
        }

        if (error) {
            console.error(error);
        }
    }


    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleFamily(event) {
        this.familyFilter = event.target.value;
    }

    handleType(event) {
        this.typeFilter = event.target.value;
    }


    @track showModal = false;  
    @track selectedItem;     

    handleDetails(event) {
        const itemId = event.target.dataset.id;

        this.selectedItem = this.items.find(i => i.Id === itemId);

        if (this.selectedItem) {
            this.showModal = true;
        }
    }

    handleCloseModal() {
        this.showModal = false;
        this.selectedItem = null;
    }

}
