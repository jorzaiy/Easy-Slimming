# Weight Limits Test Plan

## Changes Made

### 1. BusinessConstants (Constants.ets)
- Changed MIN_WEIGHT from 30 to 0
- MAX_WEIGHT remains 200

### 2. WeightRecord Model (WeightRecord.ets)
- Updated constructor validation: `weight < 0 || weight > 200` (was `weight <= 0`)
- Updated validate() method: `weight < 0 || weight > 200` (was `weight <= 0`)
- Updated error messages to reflect inclusive range: "0 and 200 (inclusive)"

### 3. FormValidator (FormValidator.ets)
- No changes needed - already uses BusinessConstants.MIN_WEIGHT
- Automatically shows "0-200 kg" range now

### 4. NumericKeypad Component (NumericKeypad.ets)
- Updated validation: `weight < 0 || weight > BusinessConstants.MAX_WEIGHT` (was `weight <= 0`)
- Updated error message to use BusinessConstants.MIN_WEIGHT

### 5. Index Page (Index.ets)
- Updated validation: `weight < BusinessConstants.MIN_WEIGHT || weight > BusinessConstants.MAX_WEIGHT`
- Error message now uses BusinessConstants for consistency

### 6. WeightEntryForm and WeightEditForm
- No changes needed - already use BusinessConstants.MIN_WEIGHT/MAX_WEIGHT
- Will automatically display "0-200 kg" range

### 7. TargetWeightService (TargetWeightService.ets)
- Updated error message clarity for target weight validation
- Target weight still requires > 0 (target of 0 kg doesn't make medical sense)

## Test Cases

### Boundary Value Tests

#### Valid Cases (Should Accept):
1. **Weight = 0 kg**: Minimum acceptable value
   - Create new record via Index page
   - Create via WeightEntryForm
   - Edit existing record via WeightEditForm

2. **Weight = 0.1 kg**: Just above minimum
   - Create new record
   - Edit existing record

3. **Weight = 199.9 kg**: Just below maximum
   - Create new record
   - Edit existing record

4. **Weight = 200 kg**: Maximum acceptable value
   - Create new record via Index page
   - Create via WeightEntryForm
   - Edit existing record via WeightEditForm

5. **Weight = 100 kg**: Mid-range value
   - Verify existing functionality

#### Invalid Cases (Should Reject):
1. **Weight < 0 (e.g., -0.1 kg)**: Below minimum
   - Should show error: "体重应在 0-200 kg 范围内"
   - Test in Index page NumericKeypad
   - Test in WeightEntryForm
   - Test in WeightEditForm

2. **Weight > 200 (e.g., 200.1 kg)**: Above maximum
   - Should show error: "体重应在 0-200 kg 范围内"
   - Test in all input forms

3. **Empty/Invalid Input**:
   - Empty string
   - Non-numeric values (letters, special chars)
   - Should show appropriate error messages

### UI Display Tests

1. **Range Hints in WeightEntryForm**:
   - Should display: "范围：0-200 kg"

2. **Range Hints in WeightEditForm**:
   - Should display: "范围：0-200 kg"

3. **Error Messages**:
   - All error messages should reference "0-200 kg" range
   - Should be consistent across all forms

### Integration Tests

1. **Database Persistence**:
   - Create record with weight = 0
   - Verify it saves to database
   - Query and verify it displays correctly in History

2. **Chart Display**:
   - Create records with boundary values (0, 0.1, 199.9, 200)
   - Verify they display correctly on WeightChart

3. **Statistics Dashboard**:
   - Create records with boundary values
   - Verify calculations (min, max, avg) work correctly
   - Check BMI calculations with edge cases

4. **Data Export/Import**:
   - Export records with boundary values to JSON/CSV
   - Import them back
   - Verify validation accepts them

### Target Weight Tests

1. **Target Weight (Still Requires > 0)**:
   - Try setting target = 0: Should reject
   - Try setting target = 0.1: Should accept
   - Try setting target = 200: Should accept
   - Error message should indicate "greater than 0 and up to 200"

## Expected Results

### All validation layers should accept 0-200 kg (inclusive):
- ✅ BusinessConstants: MIN_WEIGHT = 0, MAX_WEIGHT = 200
- ✅ FormValidator: Uses BusinessConstants
- ✅ WeightRecord constructor: weight >= 0 && weight <= 200
- ✅ WeightRecord.validate(): weight >= 0 && weight <= 200
- ✅ NumericKeypad: weight >= 0 && weight <= 200
- ✅ Index page: weight >= 0 && weight <= 200
- ✅ UI forms: Display "0-200 kg" range

### Target weight validation (separate business rule):
- ✅ Requires weight > 0 (not >= 0)
- ✅ Maximum of 200 kg

## Manual Testing Steps

1. **Build and run the app**
2. **Test Index Page NumericKeypad**:
   - Enter 0, click confirm → Should save successfully
   - Enter 200, click confirm → Should save successfully
   - Try entering 201 → Should show error

3. **Test WeightEntryForm** (pages/WeightEntryForm):
   - Navigate to entry form
   - Input 0 kg → Should show valid range hint
   - Submit → Should save successfully
   - Check error message format matches "0-200 kg"

4. **Test WeightEditForm** (edit existing record):
   - Edit a record to 0 kg → Should accept
   - Edit to 200 kg → Should accept
   - Try 201 kg → Should reject with proper message

5. **Test History Page**:
   - Verify records with weight = 0 display correctly
   - Verify records with weight = 200 display correctly

6. **Test Chart Page**:
   - Verify edge case weights appear on chart
   - Check scaling handles 0 kg properly

7. **Test Statistics Dashboard**:
   - Verify BMI calculations with edge weights
   - Check min/max/avg calculations include boundary values

8. **Test Settings/Target Weight**:
   - Try setting target to 0 → Should reject
   - Try setting target to 0.1 → Should accept

## Regression Tests

Ensure existing functionality still works:
- Mid-range weights (30-100 kg) still work as before
- All CRUD operations function correctly
- Navigation between pages works
- Data persistence is maintained
- Charts and statistics calculate correctly
