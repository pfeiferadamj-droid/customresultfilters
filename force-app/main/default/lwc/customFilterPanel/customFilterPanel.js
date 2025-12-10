import { LightningElement, api } from 'lwc';

/**
 * Custom Filter Panel Component
 * Based on Salesforce searchFiltersPanel but with category-specific logic
 */
export default class CustomFilterPanel extends LightningElement {
    @api category;
    @api filters;
    @api isMyProducts = false;

    // Track whether to show all account end users (My Products only)
    showAllAccountEndUsers = false;

    /**
     * Get the filters header label
     */
    get filtersHeader() {
        return 'Filters';
    }

    /**
     * Get the clear all button label
     */
    get clearAllLabel() {
        return 'Clear All';
    }

    /**
     * Get normalized filters
     */
    get normalizedFilters() {
        return this.filters || [];
    }

    /**
     * Check if there are any filters to display
     */
    get hasFilters() {
        return this.normalizedFilters.length > 0;
    }

    /**
     * Handle filter value toggle
     */
    handleFilterToggle(event) {
        const filterId = event.detail.filterId;
        const value = event.detail.value;
        const checked = event.detail.checked;

        // Dispatch to parent
        this.dispatchEvent(new CustomEvent('filterchange', {
            bubbles: true,
            composed: true,
            detail: {
                filterId: filterId,
                value: value,
                checked: checked
            }
        }));
    }

    /**
     * Handle clear all button click
     */
    handleClearAll(event) {
        event.preventDefault();

        // Dispatch to parent
        this.dispatchEvent(new CustomEvent('clearall', {
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Handle end user scope toggle (My Products category only)
     */
    handleEndUserScopeToggle(event) {
        this.showAllAccountEndUsers = event.target.checked;

        // Dispatch to parent
        this.dispatchEvent(new CustomEvent('enduserscope', {
            bubbles: true,
            composed: true,
            detail: {
                checked: this.showAllAccountEndUsers
            }
        }));
    }
}
