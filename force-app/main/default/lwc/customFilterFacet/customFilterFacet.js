import { LightningElement, api } from 'lwc';

/**
 * Custom Filter Facet Component
 * Based on Salesforce searchFacet but simplified for custom use cases
 */
export default class CustomFilterFacet extends LightningElement {
    @api filterData;

    // Track expanded/collapsed state
    _expanded = true;

    // Debounce timer for text input
    _textInputDebounceTimer;

    connectedCallback() {
        // Debug logging
        console.log('CustomFilterFacet connected with data:', JSON.stringify(this.filterData));
    }

    /**
     * Get normalized filter data
     */
    get normalizedFilterData() {
        const normalized = {
            id: this.filterData?.id || '',
            label: this.filterData?.label || '',
            fieldType: this.filterData?.fieldType || 'text',
            values: this.filterData?.values || [],
            selectedValues: this.filterData?.selectedValues || []
        };
        console.log('Normalized filter data:', JSON.stringify(normalized));
        return normalized;
    }

    /**
     * Get filter label
     */
    get filterLabel() {
        return this.normalizedFilterData.label;
    }

    /**
     * Get filter values
     */
    get filterValues() {
        return this.normalizedFilterData.values;
    }

    /**
     * Get checkbox options formatted for lightning-checkbox-group
     * lightning-checkbox-group expects: [{ label: 'Label', value: 'value' }]
     */
    get checkboxOptions() {
        const values = this.filterValues;
        if (!values || values.length === 0) {
            return [];
        }

        // Transform to lightning-checkbox-group format
        return values.map(item => {
            // Handle both object format and simple string format
            if (typeof item === 'object') {
                return {
                    label: item.label || item.value,
                    value: item.value || item.label
                };
            }
            return {
                label: item,
                value: item
            };
        });
    }

    /**
     * Check if filter has values
     */
    get hasValues() {
        return this.filterValues && this.filterValues.length > 0;
    }

    /**
     * Check if filter is checkbox type
     */
    get isCheckbox() {
        const fieldType = this.normalizedFilterData.fieldType;
        return fieldType === 'checkbox' || fieldType === 'boolean' || fieldType === 'picklist' || fieldType === 'multipicklist';
    }

    /**
     * Check if filter is lookup type
     */
    get isLookup() {
        return this.normalizedFilterData.fieldType === 'lookup' || this.normalizedFilterData.fieldType === 'reference';
    }

    /**
     * Check if filter is text type
     */
    get isText() {
        return this.normalizedFilterData.fieldType === 'text' || this.normalizedFilterData.fieldType === 'string';
    }

    /**
     * Get chevron icon name based on expanded state
     */
    get iconName() {
        return this._expanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    /**
     * Get facet content classes
     */
    get facetContentClasses() {
        return this._expanded ? 'facet-content' : 'facet-content slds-hide';
    }

    /**
     * Handle facet header toggle
     */
    handleHeaderToggle() {
        this._expanded = !this._expanded;
    }

    /**
     * Handle checkbox value change
     * Handles different event types from lightning-checkbox-group vs lightning-input
     */
    handleCheckboxChange(event) {
        console.log('handleCheckboxChange called', event);
        console.log('event.detail:', JSON.stringify(event.detail));
        console.log('event.target:', event.target);

        event.stopPropagation();

        const filterId = this.normalizedFilterData.id;

        // Check if this is from lightning-checkbox-group (picklist/multi-select)
        if (event.detail && event.detail.value && Array.isArray(event.detail.value)) {
            console.log('Checkbox group event detected');
            // lightning-checkbox-group returns array of selected values
            const newValues = event.detail.value;
            const oldValues = this.normalizedFilterData.selectedValues || [];

            // Determine which value was added or removed
            const addedValues = newValues.filter(v => !oldValues.includes(v));
            const removedValues = oldValues.filter(v => !newValues.includes(v));

            // Dispatch event for each changed value
            if (addedValues.length > 0) {
                console.log('Dispatching events for added values:', addedValues);
                addedValues.forEach(value => {
                    const eventDetail = {
                        filterId: filterId,
                        value: value,
                        checked: true
                    };
                    console.log('Dispatching filtertoggle event:', eventDetail);
                    this.dispatchEvent(new CustomEvent('filtertoggle', {
                        bubbles: true,
                        composed: true,
                        detail: eventDetail
                    }));
                });
            }

            if (removedValues.length > 0) {
                console.log('Dispatching events for removed values:', removedValues);
                removedValues.forEach(value => {
                    const eventDetail = {
                        filterId: filterId,
                        value: value,
                        checked: false
                    };
                    console.log('Dispatching filtertoggle event:', eventDetail);
                    this.dispatchEvent(new CustomEvent('filtertoggle', {
                        bubbles: true,
                        composed: true,
                        detail: eventDetail
                    }));
                });
            }
        } else {
            console.log('Individual checkbox/input event detected');
            // lightning-input checkbox or text input
            const value = event.target.value;
            const checked = event.target.checked !== undefined ? event.target.checked : true;

            const eventDetail = {
                filterId: filterId,
                value: value,
                checked: checked
            };
            console.log('Dispatching filtertoggle event:', eventDetail);
            this.dispatchEvent(new CustomEvent('filtertoggle', {
                bubbles: true,
                composed: true,
                detail: eventDetail
            }));
        }
    }

    /**
     * Handle text input change with debouncing
     */
    handleTextInput(event) {
        event.stopPropagation();

        const value = event.target.value;
        const filterId = this.normalizedFilterData.id;

        // Clear existing timer
        if (this._textInputDebounceTimer) {
            clearTimeout(this._textInputDebounceTimer);
        }

        // Set new timer to debounce input
        this._textInputDebounceTimer = setTimeout(() => {
            this.dispatchEvent(new CustomEvent('filtertoggle', {
                bubbles: true,
                composed: true,
                detail: {
                    filterId: filterId,
                    value: value,
                    checked: value !== '' // Only apply if value is not empty
                }
            }));
        }, 500); // Wait 500ms after user stops typing
    }

    /**
     * Check if a value is selected
     */
    isValueSelected(value) {
        return this.normalizedFilterData.selectedValues.includes(value);
    }
}
