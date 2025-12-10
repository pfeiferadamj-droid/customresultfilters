import { LightningElement, api } from 'lwc';

/**
 * Custom Filter Facet Component
 * Based on Salesforce searchFacet but simplified for custom use cases
 */
export default class CustomFilterFacet extends LightningElement {
    @api filterData;

    // Track expanded/collapsed state
    _expanded = true;

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
     */
    handleCheckboxChange(event) {
        const value = event.target.value;
        const checked = event.target.checked;

        this.dispatchEvent(new CustomEvent('filtertoggle', {
            bubbles: true,
            composed: true,
            detail: {
                filterId: this.normalizedFilterData.id,
                value: value,
                checked: checked
            }
        }));
    }

    /**
     * Check if a value is selected
     */
    isValueSelected(value) {
        return this.normalizedFilterData.selectedValues.includes(value);
    }
}
