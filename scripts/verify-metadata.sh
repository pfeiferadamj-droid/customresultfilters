#!/bin/bash

# Script to verify Shop_Defaults metadata is deployed and populated
# Run from project root: ./scripts/verify-metadata.sh

echo "==================================================================="
echo "Verifying B2B_Store_Defaults__mdt.Shop_Defaults metadata"
echo "==================================================================="
echo ""

# Check if sfdx/sf CLI is available
if command -v sf &> /dev/null; then
    CLI_CMD="sf"
elif command -v sfdx &> /dev/null; then
    CLI_CMD="sfdx"
else
    echo "❌ Error: Salesforce CLI (sf or sfdx) not found"
    echo "Please install: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

echo "Using CLI: $CLI_CMD"
echo ""

# Run the compact verification script
echo "Running verification via Anonymous Apex..."
echo ""

$CLI_CMD apex run -f scripts/verify-via-helper.apex

echo ""
echo "==================================================================="
echo "Verification complete! Check the output above."
echo ""
echo "Expected output should show:"
echo "  - Category IDs (18-character Salesforce IDs)"
echo "  - Category Names (Quick Turn, My Products)"
echo "  - Field names (Shape__c, Profile__c, etc.)"
echo "  - Page sizes (12, 24, 2000)"
echo "  - Values (Yes, QuickTurnDDT, etc.)"
echo ""
echo "If you see 'null' values, the metadata record is not deployed or"
echo "the fields are empty in your org."
echo "==================================================================="
