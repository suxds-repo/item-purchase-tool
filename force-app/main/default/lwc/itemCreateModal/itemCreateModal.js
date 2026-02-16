import { LightningElement, api, track } from 'lwc';
import createItem from '@salesforce/apex/ItemPurchaseController.createItem';
import ShowToastEvent from 'lightning/platformShowToastEvent';

export default class ItemCreateModal extends LightningElement {
    @api familyOptions = [];
    @api typeOptions = [];

    @track newItem = { Name:'', Description__c:'', Family__c:'', Type__c:'', Price__c:0 };

    handleChange(event) { this.newItem[event.target.name] = event.target.value; }

    handleCreate() {
        createItem({
            name: this.newItem.Name,
            description: this.newItem.Description__c,
            family: this.newItem.Family__c,
            type: this.newItem.Type__c,
            price: parseFloat(this.newItem.Price__c)
        })
        .then(item => this.dispatchEvent(new CustomEvent('created', { detail: item })))
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating Item',
                    message: error.body?.message || error.message,
                    variant: 'error'
                })
            );
        });
    }

    handleCancel() { this.dispatchEvent(new CustomEvent('canceled')); }
}
