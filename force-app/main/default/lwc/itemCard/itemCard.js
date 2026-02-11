import { LightningElement, api } from 'lwc';

export default class ItemCard extends LightningElement {
    @api item;

    handleDetails() {
        this.dispatchEvent(new CustomEvent('detailsclicked', { detail: this.item.Id }));
    }
}
