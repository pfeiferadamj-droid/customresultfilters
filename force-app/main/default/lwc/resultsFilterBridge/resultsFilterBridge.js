import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

/**
 * Bridge component to connect customResultsFilter events with native Salesforce results components
 * This component listens for filter events and updates the URL with filter parameters
 * that native search/results components can consume
 */
export default class ResultsFilterBridge extends NavigationMixin(LightningElement) {
    @api categoryName;

    currentFilters = {};

    // Wire to current page reference
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        // Listen for filter events from customResultsFilter
        window.addEventListener('filterchange', this.handleFilterChange.bind(this));
        window.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('filterchange', this.handleFilterChange.bind(this));
        window.removeEventListener('clearallfilters', this.handleClearAllFilters.bind(this));
    }

    handleFilterChange(event) {
        // Only process if this is the right category
        if (event.detail.category !== this.categoryName) {
            return;
        }

        const { filterId, value, checked } = event.detail;

        // Update filter state
        if (!this.currentFilters[filterId]) {
            this.currentFilters[filterId] = new Set();
        }

        if (checked) {
            this.currentFilters[filterId].add(value);
        } else {
            this.currentFilters[filterId].delete(value);
        }

        // Update URL or dispatch event for native component
        this.updateNativeResults();
    }

    handleClearAllFilters(event) {
        if (event.detail.category !== this.categoryName) {
            return;
        }

        this.currentFilters = {};
        this.updateNativeResults();
    }

    /**
     * Update native results component
     * This can be done via:
     * 1. URL parameter updates (for search components that read from URL)
     * 2. Custom event dispatch (for components that listen to events)
     * 3. Direct API calls if the native component exposes public methods
     */
    updateNativeResults() {
        // Method 1: Update URL parameters (recommended for Experience Cloud search)
        this.updateUrlParameters();

        // Method 2: Dispatch a custom event that native components might listen to
        this.dispatchFilterUpdateEvent();
    }

    /**
     * Update URL parameters with current filters
     * Native Salesforce search components often read refinements from URL
     */
    updateUrlParameters() {
        if (!this.pageRef) return;

        // Build refinement string for Salesforce search
        // Format: refinement=fieldName:value1,value2|anotherField:value3
        const refinements = this.buildRefinementString();

        // Navigate to update URL params
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.pathname
            },
            state: {
                ...this.pageRef.state,
                refinement: refinements || undefined
            }
        }, true); // Replace history state
    }

    /**
     * Build refinement string compatible with Salesforce search
     */
    buildRefinementString() {
        const refinementParts = [];

        for (const [filterId, values] of Object.entries(this.currentFilters)) {
            if (values.size > 0) {
                const valueString = Array.from(values).join(',');

                // Map your filter IDs to actual field API names
                const fieldName = this.mapFilterIdToFieldName(filterId);
                refinementParts.push(`${fieldName}:${valueString}`);
            }
        }

        return refinementParts.join('|');
    }

    /**
     * Map filter IDs to actual Salesforce field API names
     * Update this mapping based on your field structure
     */
    mapFilterIdToFieldName(filterId) {
        const fieldMapping = {
            'productCode': 'ProductCode',
            'shape': 'Shape__c',
            'rushReady': 'Rush_Ready__c',
            'endUser': 'End_User__c'
        };

        return fieldMapping[filterId] || filterId;
    }

    /**
     * Dispatch a custom event with filter data
     * Use this if you have custom results components listening for filter updates
     */
    dispatchFilterUpdateEvent() {
        // Convert Set to Array for event detail
        const filtersArray = {};
        for (const [key, valueSet] of Object.entries(this.currentFilters)) {
            filtersArray[key] = Array.from(valueSet);
        }

        const filterEvent = new CustomEvent('resultsfilterupdate', {
            bubbles: true,
            composed: true,
            detail: {
                category: this.categoryName,
                filters: filtersArray
            }
        });

        this.dispatchEvent(filterEvent);
    }
}
