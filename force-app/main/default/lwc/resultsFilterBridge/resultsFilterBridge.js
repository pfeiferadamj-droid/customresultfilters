import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import FILTER_CHANGE_CHANNEL from '@salesforce/messageChannel/FilterChangeChannel__c';

/**
 * Bridge component to connect customResultsFilter events with native Salesforce results components
 * This component listens for filter events via LMS and updates the URL with filter parameters
 * that native search/results components can consume
 */
export default class ResultsFilterBridge extends NavigationMixin(LightningElement) {
    @api categoryName;

    currentFilters = {};

    // Lightning Message Service
    @wire(MessageContext)
    messageContext;

    subscription = null;

    // Wire to current page reference
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        // Subscribe to Lightning Message Service for filter events
        this.subscribeToFilterMessages();

        // Also listen for DOM events (for backward compatibility)
        this.addEventListener('filterchange', this.handleFilterChange.bind(this));
        this.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));
    }

    disconnectedCallback() {
        // Unsubscribe from LMS
        this.unsubscribeFromFilterMessages();

        // Remove DOM event listeners
        this.removeEventListener('filterchange', this.handleFilterChange.bind(this));
        this.removeEventListener('clearallfilters', this.handleClearAllFilters.bind(this));
    }

    /**
     * Subscribe to Lightning Message Service for filter events
     */
    subscribeToFilterMessages() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                FILTER_CHANGE_CHANNEL,
                (message) => this.handleLMSMessage(message)
            );
            console.log('resultsFilterBridge: Subscribed to LMS filter messages');
        }
    }

    /**
     * Unsubscribe from Lightning Message Service
     */
    unsubscribeFromFilterMessages() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
            console.log('resultsFilterBridge: Unsubscribed from LMS filter messages');
        }
    }

    /**
     * Handle Lightning Message Service messages
     */
    handleLMSMessage(message) {
        console.log('resultsFilterBridge: Received LMS message:', message);

        if (message.action === 'filterchange') {
            // Process filter change from LMS
            this.handleFilterChange({
                detail: {
                    category: message.category,
                    filterId: message.filterId,
                    value: message.value,
                    checked: message.checked
                }
            });
        } else if (message.action === 'clearall') {
            // Process clear all from LMS
            this.handleClearAllFilters({
                detail: {
                    category: message.category
                }
            });
        }
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
     * Native Salesforce search components read refinements from URL
     */
    updateUrlParameters() {
        console.log('resultsFilterBridge: Updating URL parameters');

        // Build refinement JSON for Salesforce Commerce search
        const refinementsJSON = this.buildRefinementsJSON();

        console.log('resultsFilterBridge: Built refinements JSON:', refinementsJSON);

        // Update URL with refinements parameter
        const url = new URL(window.location.href);

        if (refinementsJSON) {
            // Double encode for Salesforce Commerce
            const encoded = encodeURIComponent(encodeURIComponent(refinementsJSON));
            url.searchParams.set('refinements', encoded);
        } else {
            url.searchParams.delete('refinements');
        }

        // Update the URL without full page reload
        window.history.replaceState({}, '', url.toString());

        console.log('resultsFilterBridge: Updated URL:', url.toString());

        // Dispatch a custom event to notify results component of URL change
        window.dispatchEvent(new CustomEvent('refinementchange', {
            detail: { refinements: refinementsJSON }
        }));
    }

    /**
     * Build refinements JSON compatible with Salesforce Commerce ConnectApi
     * Format: [{"nameOrId":"Shape__c","attributeType":"Custom","values":["Dad Hat"]}]
     */
    buildRefinementsJSON() {
        const refinements = [];

        for (const [filterId, values] of Object.entries(this.currentFilters)) {
            if (values.size > 0) {
                const refinement = {
                    nameOrId: this.mapFilterIdToFieldName(filterId),
                    attributeType: this.getAttributeType(filterId),
                    values: Array.from(values)
                };
                refinements.push(refinement);
            }
        }

        return refinements.length > 0 ? JSON.stringify(refinements) : null;
    }

    /**
     * Get attribute type for a field (Standard, Custom, or ProductAttribute)
     */
    getAttributeType(filterId) {
        const typeMapping = {
            'productCode': 'Standard',
            'shape': 'Custom',
            'rushReady': 'Custom',
            'endUser': 'Custom'
        };

        return typeMapping[filterId] || 'Custom';
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
