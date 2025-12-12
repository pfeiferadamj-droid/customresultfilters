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

    /**
     * Get normalized filter data
     */
    get normalizedFilterData() {
        return {
            id: this.filterData?.id || '',
            label: this.filterData?.label || '',
            fieldType: this.filterData?.fieldType || 'text',
            values: this.filterData?.values || [],
            selectedValues: this.filterData?.selectedValues || []
        };
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
     * Check if filter has values
     */
    get hasValues() {
        return this.filterValues.length > 0;
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
        event.stopPropagation();

        const filterId = this.normalizedFilterData.id;

        // Check if this is from lightning-checkbox-group (picklist/multi-select)
        if (event.detail && event.detail.value && Array.isArray(event.detail.value)) {
            // lightning-checkbox-group returns array of selected values
            const newValues = event.detail.value;
            const oldValues = this.normalizedFilterData.selectedValues || [];

            // Determine which value was added or removed
            const addedValues = newValues.filter(v => !oldValues.includes(v));
            const removedValues = oldValues.filter(v => !newValues.includes(v));

            // Dispatch event for each changed value
            if (addedValues.length > 0) {
                addedValues.forEach(value => {
                    this.dispatchEvent(new CustomEvent('filtertoggle', {
                        bubbles: true,
                        composed: true,
                        detail: {
                            filterId: filterId,
                            value: value,
                            checked: true
                        }
                    }));
                });
            }

            if (removedValues.length > 0) {
                removedValues.forEach(value => {
                    this.dispatchEvent(new CustomEvent('filtertoggle', {
                        bubbles: true,
                        composed: true,
                        detail: {
                            filterId: filterId,
                            value: value,
                            checked: false
                        }
                    }));
                });
            }
        } else {
            // lightning-input checkbox or text input
            const value = event.target.value;
            const checked = event.target.checked !== undefined ? event.target.checked : true;

            this.dispatchEvent(new CustomEvent('filtertoggle', {
                bubbles: true,
                composed: true,
                detail: {
                    filterId: filterId,
                    value: value,
                    checked: checked
                }
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
