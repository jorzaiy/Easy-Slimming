# NumericKeypad Component - Manual Testing Guide

This document provides a manual testing checklist to verify all key behaviors of the NumericKeypad component.

## Test Environment Setup

The NumericKeypad component is currently integrated into the Index.ets page:
1. Launch the application
2. Navigate to the home page (Index)
3. The keypad appears in the right-most column under "体重输入"

## Test Cases

### 1. Digit Entry Tests

#### Test 1.1: Basic Single Digit Entry
- **Action**: Press digit buttons 1-9 individually
- **Expected**: Each digit appears in the display area
- **Verify**: Display shows the pressed digit
- **Pass**: ✓ / ✗

#### Test 1.2: Multiple Digit Entry
- **Action**: Press 1 → 2 → 3 → 4
- **Expected**: Display shows "1234"
- **Verify**: Digits accumulate in order
- **Pass**: ✓ / ✗

#### Test 1.3: Leading Zero Replacement
- **Action**: Press 0 → 5
- **Expected**: Display shows "5" (not "05")
- **Verify**: Leading zero is replaced
- **Pass**: ✓ / ✗

#### Test 1.4: Multiple Leading Zeros
- **Action**: Press 0 → 0 → 3
- **Expected**: Display shows "0" then "3"
- **Verify**: Cannot enter multiple leading zeros, third digit replaces them
- **Pass**: ✓ / ✗

#### Test 1.5: Zero After Non-Zero
- **Action**: Press 5 → 0 → 0
- **Expected**: Display shows "500"
- **Verify**: Zeros can be appended after non-zero digit
- **Pass**: ✓ / ✗

### 2. Decimal Point Tests

#### Test 2.1: Decimal After Integer
- **Action**: Press 5 → . 
- **Expected**: Display shows "5."
- **Verify**: Decimal point appended successfully
- **Pass**: ✓ / ✗

#### Test 2.2: Decimal After Decimal
- **Action**: Press 5 → . → .
- **Expected**: Display shows "5." (second . ignored)
- **Verify**: Only one decimal point allowed
- **Pass**: ✓ / ✗

#### Test 2.3: Decimal Without Integer (Auto-Prefix)
- **Action**: Press . (without entering any digit first)
- **Expected**: Display shows "0."
- **Verify**: "0." is auto-prefixed
- **Pass**: ✓ / ✗

#### Test 2.4: Decimal with Multiple Digits
- **Action**: Press 1 → 2 → 3 → .
- **Expected**: Display shows "123."
- **Verify**: Decimal appended correctly
- **Pass**: ✓ / ✗

#### Test 2.5: Digits After Decimal
- **Action**: Press 7 → . → 5 → 3
- **Expected**: Display shows "7.53"
- **Verify**: Decimal places entered correctly
- **Pass**: ✓ / ✗

### 3. Delete (←) Button Tests

#### Test 3.1: Delete Single Digit
- **Action**: Press 5 → Delete
- **Expected**: Display shows empty (or "0" placeholder)
- **Verify**: Digit is removed
- **Pass**: ✓ / ✗

#### Test 3.2: Delete from Multi-Digit Number
- **Action**: Press 1 → 2 → 3 → Delete
- **Expected**: Display shows "12"
- **Verify**: Last digit removed
- **Pass**: ✓ / ✗

#### Test 3.3: Delete Decimal Point
- **Action**: Press 5 → . → Delete
- **Expected**: Display shows "5"
- **Verify**: Decimal point removed
- **Pass**: ✓ / ✗

#### Test 3.4: Delete Multiple Times
- **Action**: Press 1 → 2 → 3 → Delete → Delete
- **Expected**: Display shows "1"
- **Verify**: Each delete removes one character
- **Pass**: ✓ / ✗

#### Test 3.5: Delete on Empty Display
- **Action**: Press Delete (when display is empty)
- **Expected**: Display remains empty
- **Verify**: No error, nothing happens
- **Pass**: ✓ / ✗

#### Test 3.6: Delete Clears Error Message
- **Action**: Press Confirm (without entering value) → then press any digit → Delete
- **Expected**: Error message disappears before display updates
- **Verify**: Error cleared when user interacts
- **Pass**: ✓ / ✗

### 4. Clear (C) Button Tests

#### Test 4.1: Clear Value
- **Action**: Press 1 → 2 → 3 → Clear (C 清空)
- **Expected**: Display becomes empty
- **Verify**: All input cleared
- **Pass**: ✓ / ✗

#### Test 4.2: Clear with Decimal
- **Action**: Press 5 → . → 7 → Clear
- **Expected**: Display becomes empty
- **Verify**: Decimal and all digits cleared
- **Pass**: ✓ / ✗

#### Test 4.3: Clear on Empty Display
- **Action**: Press Clear (when display is already empty)
- **Expected**: Display remains empty, no error
- **Verify**: No side effects
- **Pass**: ✓ / ✗

#### Test 4.4: Clear Clears Error Message
- **Action**: Press Confirm (to generate error) → then press Clear
- **Expected**: Both value and error message are cleared
- **Verify**: Display area shows empty with no error text
- **Pass**: ✓ / ✗

### 5. Confirm (✓) Button Tests

#### Test 5.1: Confirm Valid Single Digit
- **Action**: Press 7 → Confirm (✓ 确认)
- **Expected**: Toast message "体重记录保存成功" appears
- **Verify**: Confirm succeeded
- **Pass**: ✓ / ✗

#### Test 5.2: Confirm Valid Decimal Number
- **Action**: Press 7 → . → 5 → Confirm
- **Expected**: Toast message appears, record saved
- **Verify**: Decimal value accepted
- **Pass**: ✓ / ✗

#### Test 5.3: Confirm Empty Input
- **Action**: Press Confirm (without entering anything)
- **Expected**: Error message "请输入体重" displays in red
- **Verify**: Error displayed, no save
- **Pass**: ✓ / ✗

#### Test 5.4: Confirm Out of Range (Too Low)
- **Action**: Press 0 (then try to confirm)
- **Expected**: Error message "体重应在 0-200 kg 范围内" displays
- **Verify**: Value <= 0 rejected
- **Pass**: ✓ / ✗

#### Test 5.5: Confirm Out of Range (Too High)
- **Action**: Press 2 → 0 → 1 → Confirm
- **Expected**: Error message "体重应在 0-200 kg 范围内" displays
- **Verify**: Value > 200 rejected
- **Pass**: ✓ / ✗

#### Test 5.6: Confirm Valid Edge Cases
- **Action**: 
  - First: Press 0.1 → Confirm (minimum valid)
  - Then: Clear and Press 200 → Confirm (maximum valid)
- **Expected**: Both should save successfully
- **Verify**: Edge values accepted
- **Pass**: ✓ / ✗

### 6. Cancel (✗) Button Tests

#### Test 6.1: Cancel Clears Everything
- **Action**: Press 1 → 2 → 3 → Cancel (✗ 取消)
- **Expected**: Display becomes empty, no save occurs
- **Verify**: Input discarded
- **Pass**: ✓ / ✗

#### Test 6.2: Cancel with Error
- **Action**: Press Confirm (to generate error) → Cancel
- **Expected**: Both value and error are cleared
- **Verify**: All cleared
- **Pass**: ✓ / ✗

#### Test 6.3: Cancel Multiple Times
- **Action**: Press 1 → Cancel → 2 → Cancel
- **Expected**: Each cancel clears the value
- **Verify**: Multiple cancels work
- **Pass**: ✓ / ✗

### 7. State Transitions Tests

#### Test 7.1: Error Clears on Digit Entry
- **Action**: Press Confirm (error) → Press 5
- **Expected**: Error message disappears, display shows "5"
- **Verify**: Error cleared automatically
- **Pass**: ✓ / ✗

#### Test 7.2: Error Clears on Decimal Entry
- **Action**: Press Confirm (error) → Press .
- **Expected**: Error disappears, display shows "0."
- **Verify**: Error cleared
- **Pass**: ✓ / ✗

#### Test 7.3: Error Clears on Delete
- **Action**: Press Confirm (error) → Press Delete
- **Expected**: Error disappears
- **Verify**: Error cleared
- **Pass**: ✓ / ✗

#### Test 7.4: Multiple Attempts with Correction
- **Action**: 
  - Press 2 → 0 → 1 → Confirm (error)
  - Press Delete → Delete → Delete → 7 → Confirm
- **Expected**: First attempt fails, second succeeds
- **Verify**: Can recover from error
- **Pass**: ✓ / ✗

### 8. Display Area Tests

#### Test 8.1: Display Shows "0" When Empty
- **Action**: Open page (initial state)
- **Expected**: Display area shows "0" placeholder
- **Verify**: Placeholder visible
- **Pass**: ✓ / ✗

#### Test 8.2: Display Shows Entered Value
- **Action**: Press 7 → 5 → .
- **Expected**: Display shows "75." in large bold blue text
- **Verify**: Value displayed correctly
- **Pass**: ✓ / ✗

#### Test 8.3: Error Display Color
- **Action**: Press Confirm (to generate error)
- **Expected**: Display text changes to red
- **Verify**: Error state color is red
- **Pass**: ✓ / ✗

#### Test 8.4: Error Message Above Display
- **Action**: Press Confirm (to generate error)
- **Expected**: Error message text appears above the large number
- **Verify**: Layout shows error message on top
- **Pass**: ✓ / ✗

### 9. Button State Tests

#### Test 9.1: Button Enable/Disable Responsiveness
- **Action**: Observe buttons during and after operations
- **Expected**: Buttons are always enabled and clickable
- **Verify**: No disabled state unless intentionally disabled
- **Pass**: ✓ / ✗

#### Test 9.2: Button Colors
- **Expected Colors**:
  - Digit buttons (1-9, 0, .): Blue
  - Delete button: Orange/Warning
  - Clear button: Gray/Secondary
  - Confirm button: Green/Success
  - Cancel button: Red/Error
- **Verify**: All buttons have correct colors
- **Pass**: ✓ / ✗

### 10. Integration Tests

#### Test 10.1: Full Input Workflow
- **Action**: 
  1. Enter 72.5
  2. Press Confirm
  3. Verify record saved in history
- **Expected**: 
  - Toast shows success
  - Latest record displays 72.5 kg
- **Verify**: Integration with DAO works
- **Pass**: ✓ / ✗

#### Test 10.2: Edit and Retry
- **Action**:
  1. Enter 250 (out of range)
  2. Press Confirm (get error)
  3. Press Delete three times
  4. Enter 75
  5. Press Confirm
- **Expected**: First attempt fails, second succeeds
- **Verify**: Can correct and retry
- **Pass**: ✓ / ✗

#### Test 10.3: Multiple Entries
- **Action**: Enter and confirm multiple values consecutively
- **Expected**: Each clears display for next entry
- **Verify**: Component resets between entries
- **Pass**: ✓ / ✗

## Summary

Total Test Cases: 58
Passed: ___/58
Failed: ___/58
Notes: ________________________________________________________________________________

## Known Behaviors

1. **Leading Zero Handling**: Pressing 0 followed by any non-zero digit replaces the 0
2. **Decimal Auto-Prefix**: Pressing . without any digits first results in "0."
3. **Validation**: Range check is 0 < weight <= 200 (exclusive of 0)
4. **Error Persistence**: Error clears on next user interaction
5. **Callback Order**: onValueChange fires before display update for digits

## Edge Cases Verified

- [ ] Very large numbers (123456789)
- [ ] Many decimal places (0.123456789)
- [ ] Rapid button presses
- [ ] System low memory conditions
- [ ] Orientation changes (if applicable)
- [ ] Background/foreground transitions

## Performance Notes

- Display updates: Should be instant
- Button response: Should be immediate
- No noticeable lag during rapid input
- Memory usage: Should be minimal (single numeric string)

## Regression Tests

Before deploying new versions, verify:
- [ ] All 10 test categories pass
- [ ] No new errors in console logs
- [ ] Database saves work correctly
- [ ] Error messages display properly
- [ ] Component clears between uses
