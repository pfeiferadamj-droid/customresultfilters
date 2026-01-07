import { LightningElement, api } from 'lwc';

/**
 * Custom Filter Panel Component
 * Renders filter groups with checkboxes for user selection
 */
export default class CustomFilterPanel extends LightningElement {
    @api category;
    @api isMyProducts = false;
    @api accountName = '';
    @api showAllAccountEndUsers = false;

    _filters = [];

    /**
     * Filters to display
     * Transforms filter data to add computed properties for template rendering
     */
    @api
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value ? value.map(filter => ({
            ...filter,
            isCheckbox: filter.fieldType === 'checkbox',
            isPicklist: filter.fieldType === 'picklist',
            isLookup: filter.fieldType === 'lookup'
        })) : [];
    }

    /**
     * Get scope toggle label for My Products
     */
    get scopeToggleLabel() {
        return `Show all products for ${this.accountName}`;
    }

    /**
     * Check if there are any filters to display
     */
    get hasFilters() {
        return this._filters && this._filters.length > 0;
    }

    /**
     * Handle filter checkbox change
     */
    handleFilterChange(event) {
        const filterId = event.target.dataset.filterId;
        const value = event.target.dataset.value;
        const checked = event.target.checked;

        console.log('customFilterPanel: Filter changed:', { filterId, value, checked });

        // Dispatch event to parent component
        this.dispatchEvent(new CustomEvent('filterchange', {
            detail: {
                category: this.category,
                filterId: filterId,
                value: value,
                checked: checked
            },
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Handle clear all filters
     */
    handleClearAll() {
        console.log('customFilterPanel: Clear all filters');

        // Dispatch event to parent component
        this.dispatchEvent(new CustomEvent('clearall', {
            detail: {
                category: this.category
            },
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Handle end user scope toggle
     */
    handleScopeToggle(event) {
        const checked = event.target.checked;
        console.log('customFilterPanel: Scope toggled:', checked);

        // Dispatch event to parent component
        this.dispatchEvent(new CustomEvent('enduserscope', {
            detail: {
                checked: checked
            },
            bubbles: true,
            composed: true
        }));
    }
}
