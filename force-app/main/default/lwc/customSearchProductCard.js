import { LightningElement, api, track, wire } from 'lwc';
import { isCmsResource, resolve } from 'experience/resourceResolver';
import { generateUrl, navigate, NavigationContext } from 'lightning/navigation';
import { AppContextAdapter, SessionContextAdapter } from 'commerce/contextApi';
import { createImageDataMap } from 'experience/picture';
import { calculateImageSizes, imageSizesDefined } from './productGalleryUtils';
import { CartStatusAdapter } from 'commerce/cartApi';
import { EVENT, PRODUCT_CLASS, QUANTITY_RULES } from './constants';
import { i18n } from './labels';

export default class CustomSearchProductCard extends LightningElement {
    static renderMode = 'light';
    @track
    _imageSizes = {
        mobile: 0,
        tablet: 0,
        desktop: 0,
    };
    _displayData;
    _navigationContext;
    _productUrl;

    @wire(NavigationContext)
    wiredNavigationContext(context) {
        this._navigationContext = context;
        this.updateCallToActionButtonUrl();
    }

    @wire(SessionContextAdapter)
    sessionContext;

    @wire(AppContextAdapter)
    appContext;

    @wire(CartStatusAdapter)
    cartStatus;

    /**
     * Gets or sets the card display-data.
     * @type {?ProductCardData}
     */
    @api
    set displayData(data) {
        this._displayData = data;
        this.updateCallToActionButtonUrl();
    }
    get displayData() {
        return this._displayData;
    }

    /**
     * Gets or sets the card UI configuration.
     * @type {?ProductCardConfiguration}
     */
    @api
    configuration;

    /**
     * The current active pricebook ID
     * @type {?string}
     */
    @api
    currentPricebookId;

    /**
     * The special pricebook IDs that trigger 'c' suffix (comma-separated)
     * @type {?string}
     */
    @api
    specialPricebookIds;

    @api
    focus() {
        if (this.configuration?.showCallToActionButton) {
            const focusTarget = this.querySelector('c-common-button');
            focusTarget?.focus();
        } else {
            const index = this.fields?.findIndex((field) => field.displayData.tabStoppable) || 0;
            const focusTarget = Array.from(this.querySelectorAll('.product-field'))[index];
            focusTarget?.focus();
        }
    }

    /**
     * Gets the prices display-data formatted for pricedisplay component.
     * @type {object}
     * @readonly
     * @private
     */
    get pricingInfo() {
        const prices = this.displayData?.prices;
        return {
            negotiatedPrice: prices?.negotiatedPrice ?? '',
            listPrice: prices?.listingPrice ?? '',
            currencyIsoCode: prices?.currencyIsoCode ?? '',
        };
    }

    /**
     * Gets the aria-label for the Add to Cart button
     * @type {string}
     * @readonly
     * @private
     */
    get addToCartButtonAriaLabel() {
        if (this.displayData?.name) {
            return i18n.addToCartAriaLabel.replace('{productTitle}', this.displayData.name);
        }
        return '';
    }

    /**
     * Gets the aria-label for the View Options button
     * @type {string}
     * @readonly
     * @private
     */
    get viewOptionsButtonAriaLabel() {
        if (this.displayData?.name) {
            return i18n.viewOptionsAriaLabel.replace('{productTitle}', this.displayData.name);
        }
        return '';
    }

    /**
     * Gets the product fields
     * @type {ProductField[]}
     * @readonly
     * @private
     */
    get fields() {
        return (this.displayData?.fields ?? []).map((field) => {
            // Determine CSS class based on field name
            // Name uses heading_medium (20px), others use heading_small (18px)
            const isNameField = field.name === 'Name';
            const headingClass = isNameField ? 'slds-text-heading_medium' : 'slds-text-heading_small';
            const cssClass = `product-field ${headingClass}`;

            return {
                displayData: field,
                configuration: this.configuration?.fieldConfiguration[field.name] ?? {},
                cssClass: cssClass,
            };
        });
    }

    /**
     * Gets the default image
     * @type {ProductMediaData}
     * @readonly
     * @private
     */
    get image() {
        if (!import.meta.env.SSR) {
            calculateImageSizes(this.querySelector('.imageArea'), this._imageSizes);
        }
        const img = this.displayData?.image;
        return {
            alternateText: img?.alternateText ?? '',
            url: resolve(img?.url ?? '', false, {
                height: 460,
                width: 460,
            }),
            images:
                img?.url && isCmsResource(img?.url) && imageSizesDefined(this._imageSizes)
                    ? createImageDataMap(img.url, this._imageSizes, [1, 2])
                    : [],
        };
    }

    /**
     * Gets the container class for the card
     * @type {string}
     * @readonly
     * @private
     */
    get cardContainerClass() {
        return this.isGridLayout ? 'cardContainerGrid' : 'cardContainerList';
    }

    /**
     * Gets whether the layout is grid or not
     * @type {boolean}
     * @readonly
     * @private
     */
    get isGridLayout() {
        return this.configuration?.layout === 'grid';
    }

    /**
     * Gets the variant to apply to the action buttons
     * @type {('primary' | 'secondary' | 'tertiary')}
     * @readonly
     * @private
     */
    get actionButtonVariant() {
        if (import.meta.env.SSR) {
            return 'primary';
        }
        const section = this.template?.['querySelector']?.('section');
        const variant =
            section && globalThis?.getComputedStyle?.(section)?.getPropertyValue('--ref-c-search-product-card-button-variant');
        return ['primary', 'secondary', 'tertiary'].includes(variant) ? variant : 'primary';
    }

    /**
     * Get the text for minimum quantity guide
     * @type {?string}
     * @readonly
     * @private
     */
    get minimumText() {
        const min = Number.parseInt(this.quantityRules?.minimum ?? '', 10);
        return this.configuration?.minimumQuantityGuideText.replace('{0}', `${min}`);
    }

    /**
     * Get the text for maximum quantity guide
     * @type {?string}
     * @readonly
     * @private
     */
    get maximumText() {
        const max = Number.parseInt(this.quantityRules?.maximum ?? '', 10);
        return this.configuration?.maximumQuantityGuideText.replace('{0}', `${max}`);
    }

    /**
     * Get the text for increment quantity guide
     * @type {?string}
     * @readonly
     * @private
     */
    get incrementText() {
        const increment = Number.parseInt(this.quantityRules?.increment ?? '', 10);
        return this.configuration?.incrementQuantityGuideText.replace('{0}', `${increment}`);
    }

    /**
     * Whether the quantity provided is valid
     * @type {boolean}
     * @private
     */
    isQuantityValid = true;

    /**
     * The selected quantity value
     * @type {number}
     * @private
     */
    selectedQuantity;

    /**
     * Gets whether the 'add to cart' button is disabled
     * @type {boolean}
     * @readonly
     * @private
     */
    get addToCartButtonDisabled() {
        return this.isCartProcessing || this.configuration?.addToCartDisabled || !this.isQuantityValid;
    }

    /**
     * The computed text for add to cart button
     * @type {?string}
     * @readonly
     * @private
     */
    get addToCartButtonText() {
        return this.isCartProcessing && this.configuration?.addToCartButtonProcessingText
            ? this.configuration?.addToCartButtonProcessingText
            : this.configuration?.addToCartButtonText;
    }

    /**
     * Handler for the 'validationchanged' event
     * @param {CustomEvent} evt the event object
     * @private
     */
    handleValueChanged(evt) {
        this.isQuantityValid = evt.detail.isValid;
    }

    /**
     * Handler for quantity input change
     * @param {Event} evt the event object
     * @private
     */
    handleQuantityChange(evt) {
        this.selectedQuantity = evt.target.value;
        this.isQuantityValid = evt.target.validity.valid;
    }

    /**
     * Get all the quantity rules for quantity selector
     * @type {?PurchaseQuantityRuleData}
     * @readonly
     * @private
     */
    get quantityRules() {
        if (!this.displayData?.purchaseQuantityRule && this.configuration?.showQuantitySelector) {
            return {
                minimum: QUANTITY_RULES.DEFAULT_MIN.toString(),
                maximum: QUANTITY_RULES.DEFAULT_MAX.toString(),
                increment: QUANTITY_RULES.DEFAULT_INCREMENT.toString(),
            };
        }
        return this.displayData?.purchaseQuantityRule;
    }

    /**
     * The minimum quantity of the product
     * @type {?string}
     * @readonly
     * @private
     */
    get quantityRuleMinimum() {
        return this.quantityRules?.minimum;
    }

    /**
     * The maximum quantity of the product
     * @type {?string}
     * @readonly
     * @private
     */
    get quantityRuleMaximum() {
        return this.quantityRules?.maximum;
    }

    /**
     * The increment quantity of the product
     * @type {?string}
     * @readonly
     * @private
     */
    get quantityRuleIncrement() {
        return this.quantityRules?.increment;
    }

    /**
     * Get the label next to the inline quantity selector
     * @type {?string}
     * @readonly
     * @private
     */
    get quantitySelectorLabelText() {
        return this.configuration?.quantitySelectorLabelText;
    }

    /**
     * Gets all the quantity rules combined
     * @type {string}
     * @readonly
     * @private
     */
    get quantityRuleCombinedText() {
        const rules = [this.minimumText, this.maximumText, this.incrementText];
        return rules.filter((item) => item).join(' • ');
    }

    /**
     * Gets whether the CTA button is View Options
     * @type {boolean}
     * @readonly
     * @private
     */
    get isCTAButtonViewOptions() {
        return (
            this.displayData?.productClass === PRODUCT_CLASS.VARIATION_PARENT ||
            this.displayData?.productClass === PRODUCT_CLASS.SET ||
            ((this.displayData?.productClass === PRODUCT_CLASS.SIMPLE ||
                this.displayData?.productClass === PRODUCT_CLASS.VARIATION) &&
                Boolean(this.quantityRules) &&
                !this.configuration?.showQuantitySelector) ||
            this.isSubscriptionProduct
        );
    }

    /**
     * Gets whether the CTA button is Add to Cart
     * @type {boolean}
     * @readonly
     * @private
     */
    get isCTAButtonAddToCart() {
        return (
            this.displayData?.productClass === PRODUCT_CLASS.SIMPLE ||
            this.displayData?.productClass === PRODUCT_CLASS.VARIATION
        );
    }

    /**
     * Whether to show inline quantity selector
     * @type {boolean}
     * @readonly
     * @private
     */
    get showInlineQuantitySelector() {
        return !!(this.quantityRules && this.configuration?.showQuantitySelector);
    }

    /**
     * Whether to show inline quantity selector rules text
     * @type {boolean}
     * @readonly
     * @private
     */
    get showInlineQuantitySelectorText() {
        return !!(
            !this.isCTAButtonViewOptions &&
            this.configuration?.showQuantitySelector &&
            this.configuration?.showQuantityRulesText &&
            this.displayData?.purchaseQuantityRule
        );
    }

    /**
     * Click event handler for product card navigation
     * @param {MouseEvent | KeyboardEvent} event
     * @private
     */
    handleProductDetailPageNavigation(event) {
        event.preventDefault();
        const productId = this.displayData?.id;
        const productName = this.displayData?.name;

        this.dispatchEvent(
            new CustomEvent(EVENT.SHOW_PRODUCT_EVT, {
                detail: {
                    productId,
                    productName,
                },
            })
        );
    }

    /**
     * Whether the product is a subscription product
     * @type {boolean}
     * @readonly
     * @private
     */
    get isSubscriptionProduct() {
        return this.displayData?.productSellingModelInformation?.isSubscriptionProduct ?? false;
    }

    get subscriptionOptionsLabelText() {
        return i18n.subscriptionOptionLabel;
    }

    /**
     * Whether to show price information
     * @type {boolean}
     * @readonly
     * @private
     */
    get showPrice() {
        const { showListingPrice, showNegotiatedPrice } = this.configuration?.priceConfiguration || {};
        return !!(showListingPrice || showNegotiatedPrice);
    }

    get showNegotiatedPrice() {
        return !!this.configuration?.priceConfiguration?.showNegotiatedPrice;
    }

    get showOriginalPrice() {
        return !!this.configuration?.priceConfiguration?.showListingPrice;
    }

    /**
     * Gets the class list for quantity selector
     * @type {string}
     * @readonly
     * @private
     */
    get quantitySelectorClassList() {
        const classes = [];
        if (this.showInlineQuantitySelector) {
            classes.push('quantitySelectorContainer');
            if (this.isGridLayout) {
                classes.push('stacked');
            }
        }
        return classes.join(' ');
    }

    /**
     * Whether to show the product image
     * @type {boolean}
     * @readonly
     * @private
     */
    get showProductImage() {
        return this.configuration?.showProductImage ?? false;
    }

    /**
     * Whether to show the call to action button
     * @type {boolean}
     * @readonly
     * @private
     */
    get showCallToActionButton() {
        return this.configuration?.showCallToActionButton ?? false;
    }

    /**
     * Gets whether the cart is processing
     * @type {boolean}
     * @readonly
     * @private
     */
    get isCartProcessing() {
        return !!this.cartStatus?.data?.isProcessing || !!this.cartStatus?.loading;
    }

    /**
     * If add to cart is enabled based on guest permission
     * @type {boolean}
     * @readonly
     * @private
     */
    get isAddToCartEnabled() {
        const isLoggedIn = Boolean(this.sessionContext?.data?.isLoggedIn);
        const guestCartEnabled = Boolean(this.appContext?.data?.guestCartEnabled);
        return isLoggedIn || guestCartEnabled;
    }

    renderedCallback() {
        if (!import.meta.env.SSR) {
            calculateImageSizes(this.querySelector('.imageArea'), this._imageSizes);
        }
    }

    handleAddToCart() {
        if (!this.isAddToCartEnabled) {
            this.navigateToLogin();
            return;
        }
        if (this.isCartProcessing) {
            return;
        }
        const productId = this.displayData?.id;
        const quantity = this.selectedQuantity || this.quantityRules?.minimum || 1;
        this.dispatchEvent(
            new CustomEvent(EVENT.ADD_PRODUCT_TO_CART_EVT, {
                detail: {
                    productId,
                    quantity,
                },
            })
        );
    }

    /**
     * Handle the keydown event
     * @param {KeyboardEvent} evt the event object
     * @private
     */
    handleKeydown(evt) {
        if (evt.key === 'Enter') {
            this.handleProductDetailPageNavigation(evt);
        }
    }

    /**
     * Navigate to login page
     * @private
     */
    navigateToLogin() {
        navigate(this._navigationContext, {
            type: 'comm__namedPage',
            attributes: {
                name: 'Login',
            },
        });
    }

    updateCallToActionButtonUrl() {
        if (this._navigationContext && this?._displayData?.id) {
            this._productUrl = generateUrl(this._navigationContext, {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Product2',
                    recordId: this._displayData.id,
                    actionName: 'view',
                },
            });
        }
    }
}