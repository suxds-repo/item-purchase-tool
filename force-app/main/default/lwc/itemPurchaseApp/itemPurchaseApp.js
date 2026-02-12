import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getAccount from '@salesforce/apex/ItemPurchaseController.getAccount';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';
import getTypePicklistValues from '@salesforce/apex/ItemPurchaseController.getTypePicklistValues';
import getFamilyPicklistValues from '@salesforce/apex/ItemPurchaseController.getFamilyPicklistValues';
import createItem from '@salesforce/apex/ItemPurchaseController.createItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkoutCart from '@salesforce/apex/ItemPurchaseController.checkoutCart';
import { NavigationMixin } from 'lightning/navigation';

export default class ItemPurchaseApp extends NavigationMixin(LightningElement) {
    @track accountId;
    @track account;
    @track items = [];

    @track familyOptions = [];
    @track typeOptions = [];

    @track familyFilter = '';
    @track typeFilter = '';
    @track searchKey = '';

    @track showCreateModal = false;
    @track showDetailsModal = false;
    @track selectedItem;

    @track cart = [];
    @track showCartModal = false;



    cartColumns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Price', fieldName: 'Price__c', type: 'currency' },
        { label: 'Family', fieldName: 'Family__c' },
        { label: 'Type', fieldName: 'Type__c' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef?.state?.c__accountId) {
            this.accountId = pageRef.state.c__accountId;
        }
    }

    @wire(getAccount, { accountId: '$accountId' })
    wiredAccount({ data, error }) {
        if (data) this.account = data;
        if (error) console.error(error);
    }

    @wire(getFamilyPicklistValues)
    wiredFamily({ data }) {
        if (data) this.familyOptions = [{ label: '--All--', value: '' }, ...data.map(v => ({ label: v, value: v }))];
    }

    @wire(getTypePicklistValues)
    wiredType({ data }) {
        if (data) this.typeOptions = [{ label: '--All--', value: '' }, ...data.map(v => ({ label: v, value: v }))];
    }

    @wire(getItems, { family: '$familyFilter', type: '$typeFilter', searchKey: '$searchKey' })
    wiredItems({ data, error }) {
        if (data) this.items = data;
        if (error) console.error(error);
    }

    handleFilterChanged(event) {
        this.familyFilter = event.detail.family;
        this.typeFilter = event.detail.type;
        this.searchKey = event.detail.searchKey;
    }

    handleOpenCreateModal() { this.showCreateModal = true; }
    handleCloseCreateModal() { this.showCreateModal = false; }

    handleItemCreated(event) {
        this.items = [event.detail, ...this.items];
        this.handleCloseCreateModal();
    }

    handleDetails(event) {
        this.selectedItem = this.items.find(i => i.Id === event.detail);
        if (this.selectedItem) this.showDetailsModal = true;
    }

    handleCloseDetails() {
        this.showDetailsModal = false;
        this.selectedItem = null;
    }

    handleAddToCart(event) {

        const item = event.detail;

        const exists = this.cart.find(i => i.Id === item.Id);

        if (!exists) {
            this.cart = [...this.cart, item];
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Added to Cart',
                message: item.Name + ' added',
                variant: 'success'
            })
        );
    }


    openCartModal() {
        this.showCartModal = true;
    }

    closeCartModal() {
        this.showCartModal = false;
    }



    async handleCheckout() {

        if (this.cart.length === 0) {
            return;
        }

        try {

            const itemIds = this.cart.map(i => i.Id);

            const purchaseId = await checkoutCart({
                accountId: this.accountId,
                itemIds: itemIds
            });


            this.cart = [];
            this.showCartModal = false;


            // Redirect to Purchase record
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: purchaseId,
                    objectApiName: 'Purchase__c',
                    actionName: 'view'
                }
            });


        } catch (error) {
            console.error(error);
        }
    }

}
