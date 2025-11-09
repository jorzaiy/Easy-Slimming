#!/bin/bash

echo "=== Verification of Weight Limits Changes ==="
echo ""

echo "1. Checking BusinessConstants.MIN_WEIGHT..."
grep "MIN_WEIGHT = 0" entry/src/main/ets/common/Constants.ets && echo "✓ MIN_WEIGHT is 0" || echo "✗ MIN_WEIGHT not set to 0"

echo ""
echo "2. Checking WeightRecord constructor validation..."
grep "weight < 0 || weight > 200" entry/src/main/ets/model/WeightRecord.ets | head -1 && echo "✓ Constructor validation updated" || echo "✗ Constructor validation not updated"

echo ""
echo "3. Checking WeightRecord.validate() method..."
grep "this.weight < 0 || this.weight > 200" entry/src/main/ets/model/WeightRecord.ets && echo "✓ validate() method updated" || echo "✗ validate() method not updated"

echo ""
echo "4. Checking NumericKeypad validation..."
grep "weight < 0 || weight > BusinessConstants.MAX_WEIGHT" entry/src/main/ets/components/NumericKeypad.ets && echo "✓ NumericKeypad updated" || echo "✗ NumericKeypad not updated"

echo ""
echo "5. Checking Index.ets validation..."
grep "weight < BusinessConstants.MIN_WEIGHT || weight > BusinessConstants.MAX_WEIGHT" entry/src/main/ets/pages/Index.ets && echo "✓ Index.ets updated" || echo "✗ Index.ets not updated"

echo ""
echo "6. Checking DataExportImportService validation..."
grep "recordData.weight < 0 || recordData.weight > 200" entry/src/main/ets/data/DataExportImportService.ets && echo "✓ DataExportImportService updated" || echo "✗ DataExportImportService not updated"

echo ""
echo "7. Verifying no old 'weight <= 0' patterns remain (excluding target weight validation)..."
RESULT=$(grep -rn "weight <= 0" entry/src/main/ets --include="*.ets" | grep -v "targetWeight" | grep -v "date" | grep -v "//" | grep -v "TargetWeightService" | grep -v "FormValidator.ets:62")
if [ -z "$RESULT" ]; then
    echo "✓ No unwanted 'weight <= 0' patterns found"
else
    echo "✗ Found unwanted patterns:"
    echo "$RESULT"
fi

echo ""
echo "8. Verifying no references to '30 kg' or '30-200' remain..."
RESULT=$(grep -rn "30.*kg\|30-200\|30 - 200" entry/src/main/ets --include="*.ets")
if [ -z "$RESULT" ]; then
    echo "✓ No references to old limits found"
else
    echo "✗ Found old limit references:"
    echo "$RESULT"
fi

echo ""
echo "=== Verification Complete ==="
