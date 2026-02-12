import { LightningElement, api } from 'lwc';

export default class ItemCard extends LightningElement {

    @api item;

    handleAdd() {
        this.dispatchEvent(
            new CustomEvent('addtocart', {
                detail: this.item
            })
        );
    }

    handleDetails() {
        this.dispatchEvent(
            new CustomEvent('detailsclicked', {
                detail: this.item.Id
            })
        );
    }
}
