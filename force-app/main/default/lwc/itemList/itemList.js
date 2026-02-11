import { LightningElement, api } from 'lwc';

export default class ItemList extends LightningElement {
    @api items = [];

    handleDetails(event) {
        this.dispatchEvent(new CustomEvent('detailsclicked', { detail: event.detail }));
    }
}
