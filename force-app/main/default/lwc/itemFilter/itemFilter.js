import { LightningElement, api, track } from 'lwc';

export default class ItemFilter extends LightningElement {
    @api familyOptions = [];
    @api typeOptions = [];

    @track family = '';
    @track type = '';
    @track searchKey = '';

    handleFamilyChange(event) { this.family = event.detail.value; this.fireFilter(); }
    handleTypeChange(event) { this.type = event.detail.value; this.fireFilter(); }
    handleSearch(event) { this.searchKey = event.target.value; this.fireFilter(); }

    fireFilter() {
        this.dispatchEvent(new CustomEvent('filterchanged', {
            detail: { family: this.family, type: this.type, searchKey: this.searchKey }
        }));
    }
}
