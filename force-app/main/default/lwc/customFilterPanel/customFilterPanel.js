import { LightningElement, api, track } from 'lwc';

/**
 * Custom Filter Panel Component
 * Based on Salesforce searchFiltersPanel but with category-specific logic
 */
export default class CustomFilterPanel extends LightningElement {
    @api category;
    @api isMyProducts = false;

    // Track whether to show all account end users (My Products only)
    showAllAccountEndUsers = false;

    // Internal filters with selected values
    @track _filters = [];

    /**
     * Receive filters from parent and maintain selected state
     */
    @api
    get filters() {
        return this._filters;
    }
    set filters(value) {
        // Initialize filters if they don't exist yet
        if (!this._filters || this._filters.length === 0) {
            this._filters = value ? JSON.parse(JSON.stringify(value)) : [];
        } else if (value && value.length > 0) {
            // Merge new filter data with existing selected values
            this._filters = value.map(newFilter => {
                const existingFilter = this._filters.find(f => f.id === newFilter.id);
                if (existingFilter && existingFilter.selectedValues) {
                    // Preserve selected values
                    return {
                        ...newFilter,
                        selectedValues: existingFilter.selectedValues
                    };
                }
                return newFilter;
            });
        }
    }

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
        return this._filters || [];
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

        console.log('customFilterPanel: handleFilterToggle', {filterId, value, checked});

        // Update the filter's selected values
        this._filters = this._filters.map(filter => {
            if (filter.id === filterId) {
                let selectedValues = filter.selectedValues || [];

                if (checked) {
                    // Add value if not already selected
                    if (!selectedValues.includes(value)) {
                        selectedValues = [...selectedValues, value];
                    }
                } else {
                    // Remove value
                    selectedValues = selectedValues.filter(v => v !== value);
                }

                console.log('Updated selectedValues for', filterId, ':', selectedValues);

                return {
                    ...filter,
                    selectedValues: selectedValues
                };
            }
            return filter;
        });

        // Force re-render
        this._filters = [...this._filters];

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

        console.log('customFilterPanel: clearAll clicked');

        // Clear all selected values
        this._filters = this._filters.map(filter => ({
            ...filter,
            selectedValues: []
        }));

        // Force re-render
        this._filters = [...this._filters];

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
