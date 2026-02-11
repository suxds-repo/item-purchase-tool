import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';

import getAccount from '@salesforce/apex/ItemPurchaseController.getAccount';
import getTypePicklistValues from '@salesforce/apex/ItemPurchaseController.getTypePicklistValues';
import getFamilyPicklistValues from '@salesforce/apex/ItemPurchaseController.getFamilyPicklistValues';
import createItem from '@salesforce/apex/ItemPurchaseController.createItem';


export default class ItemPurchaseApp extends LightningElement {

    @track accountId;
    @track account;
    @track items = [];
    familyOptions = [];

    typeOptions = [];

    @track familyFilter = null;
    @track typeFilter = null;
    @track searchKey = null;

    
    @wire(getFamilyPicklistValues)
    wiredFamily({data, error}) {
        if(data){
            this.familyOptions = [{label:'--All--', value:''}, ...data.map(v => ({label:v, value:v}))];
        }
    }

    @wire(getTypePicklistValues)
    wiredType({data, error}) {
        if(data){
            this.typeOptions = [{label:'--All--', value:''}, ...data.map(v => ({label:v, value:v}))];
        }
    }


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



    @track showCreateModal = false;
    @track newItem = { Name:'', Description__c:'', Family__c:'', Type__c:'', Price__c:0 };

    openCreateModal() { this.showCreateModal = true; }
    closeCreateModal() { 
        this.showCreateModal = false; 
        this.newItem = { Name:'', Description__c:'', Family__c:'', Type__c:'', Price__c:0 };
    }


    handleNewItemChange(event){
        const field = event.target.name;
        this.newItem[field] = event.target.value;
    }


    createNewItem() {
        createItem({
            name: this.newItem.Name,
            description: this.newItem.Description__c,
            family: this.newItem.Family__c,
            type: this.newItem.Type__c,
            price: parseFloat(this.newItem.Price__c)
        })
        .then(item => {
            this.items = [item, ...this.items]; 
            this.closeCreateModal();
        })
        .catch(error => {
            console.error(error);
        });
    }

}
