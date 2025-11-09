# NumericKeypad Component Documentation

## Overview

The `NumericKeypad` is a reusable ArkUI component that provides a numeric input interface with a 4×3 keypad layout plus control buttons. It's designed for applications requiring numeric input, particularly weight tracking or similar data entry scenarios.

## Features

- **Digit Input (0-9)**: Full numeric keypad with automatic leading zero handling
- **Decimal Point Support**: Single decimal point per value with auto-prefix "0."
- **Delete Button (←)**: Remove the last character from input
- **Clear Button (C)**: Reset all input and error messages
- **Confirm Button (✓)**: Validate and confirm the numeric entry
- **Cancel Button (✗)**: Abort input operation
- **Error Display**: Visual error message highlighting with color
- **Disabled State**: Optional button disabling for UI control
- **Internal Validation Guards**: Prevents invalid input states before callback invocation

## Component Props

```typescript
interface NumericKeypadCallbacks {
  onValueChange?: (value: string) => void;  // Called on digit/decimal entry or delete
  onDelete?: (value: string) => void;       // Called when delete (←) button is pressed
  onClear?: () => void;                     // Called when clear (C) button is pressed
  onConfirm?: (value: string) => void;      // Called when confirm (✓) is pressed after validation
  onCancel?: () => void;                    // Called when cancel (✗) button is pressed
}

// Component Props
@Prop disabled?: boolean = false;           // Disables all button interactions when true
@Prop showErrorMessage?: string = '';       // Display custom error message
@Consume callbacks?: NumericKeypadCallbacks;// Callbacks for user interactions
```

## Usage Example

### Basic Usage in a Page

```typescript
import { NumericKeypad, NumericKeypadCallbacks } from '../components/NumericKeypad';

@Entry
@Component
struct MyWeightPage {
  @State displayValue: string = '';
  @State errorMessage: string = '';
  @Provide keypadCallbacks: NumericKeypadCallbacks = {};

  aboutToAppear() {
    this.setupKeypadCallbacks();
  }

  private setupKeypadCallbacks() {
    this.keypadCallbacks = {
      onValueChange: (value: string) => {
        this.displayValue = value;
        // Parent can validate and set error messages
        if (parseFloat(value) > 300) {
          this.errorMessage = '数值过大';
        }
      },
      onDelete: (value: string) => {
        console.log('Delete pressed, remaining value:', value);
      },
      onClear: () => {
        console.log('Clear pressed');
      },
      onConfirm: (value: string) => {
        // Handle the final confirmed weight value
        this.saveWeight(value);
      },
      onCancel: () => {
        // Reset the form
        this.displayValue = '';
        this.errorMessage = '';
      }
    };
  }

  build() {
    Column() {
      NumericKeypad()
    }
  }
}
```

## Input Behavior

### 1. Digit Entry
- Digits 0-9 are accepted
- Leading zeros are automatically replaced when entering non-zero digits
- Exception: "0." pattern is preserved for decimal entries

Example:
```
"0" + "5" → "5"
"0" + "0" → "0"
"5" + "0" → "50"
"" + "." → "0."
```

### 2. Decimal Point Entry
- Only one decimal point is allowed per value
- If decimal is entered with empty input, "0." is automatically prefixed
- Subsequent decimal point presses are ignored

Example:
```
"" + "." → "0."
"5" + "." → "5."
"5." + "." → "5." (unchanged)
```

### 3. Delete Operation (←)
- Removes the last character from the current value
- Calls `onDelete` callback with the remaining value
- Does nothing if value is empty

Example:
```
"123" + Delete → "12"
"12.3" + Delete → "12."
"0" + Delete → "" (empty)
```

### 4. Clear Operation (C)
- Resets the display value to empty string
- Clears any error messages
- Calls `onClear` callback

Example:
```
"123.45" + Clear → ""
errorMessage is cleared
```

### 5. Confirm Operation (✓)
- Validates that value is not empty
- Validates that value is a valid number
- Validates that value is within 0-200 kg range
- Calls `onConfirm` callback only if all validations pass
- Sets error message if validation fails

Validation rules:
- Value must not be empty: "请输入体重"
- Value must be a valid number: "请输入有效的数字"
- Value must be in range [0, 200]: "体重应在 0-200 kg 范围内"

### 6. Cancel Operation (✗)
- Clears the display value
- Clears error messages
- Calls `onCancel` callback

## Error Display

The component displays error messages in the display area:
- Error text appears in red color above the numeric display
- Error is cleared when:
  - User presses a digit or decimal point
  - User presses delete
  - User presses clear
  - Clear button is pressed

## Disabled State

Set `disabled` prop to true to disable all buttons:

```typescript
Column() {
  NumericKeypad()
    .disabled(isSaving)  // Disable keypad while saving
}
```

When disabled:
- All buttons become visually disabled
- Click handlers don't execute
- User interactions are prevented

## Validation Strategy

The NumericKeypad uses a **layered validation approach**:

1. **Internal Guards (Component Level)**
   - Single decimal point enforcement
   - Leading zero handling
   - Basic format validation

2. **Confirm-Time Validation (Component Level)**
   - Non-empty check
   - Valid number check
   - Range check (0-200 kg)

3. **Parent-Level Validation**
   - Custom business logic
   - Additional range checks
   - Database constraints
   - Set `showErrorMessage` prop to display parent validation errors

## Component Methods

### `getValue(): string`
Returns the current display value.

```typescript
const keypadRef = this;
const currentValue = keypadRef.getValue();
```

### `clear(): void`
Programmatically clears the display and error message.

```typescript
const keypadRef = this;
keypadRef.clear();
```

## Layout

The component renders in the following layout:
```
┌─────────────────────────┐
│   Display Area / Error  │ (Large number display, error message above)
├─────────────────────────┤
│  1  │  2  │  3         │ Row 1: Digit buttons
├─────────────────────────┤
│  4  │  5  │  6         │ Row 2: Digit buttons
├─────────────────────────┤
│  7  │  8  │  9         │ Row 3: Digit buttons
├─────────────────────────┤
│  0  │  .  │ ← Delete   │ Row 4: Zero, decimal, delete
├─────────────────────────┤
│ ✓ Confirm │ C Clear │ ✗ Cancel │ Row 5: Control buttons
└─────────────────────────┘
```

## Styling

Button colors:
- **Digit buttons (0-9, .)**: Primary blue (`AppColors.PRIMARY`)
- **Delete button (←)**: Warning orange (`AppColors.WARNING`)
- **Clear button (C)**: Secondary gray (`AppColors.SECONDARY`)
- **Confirm button (✓)**: Success green (`AppColors.SUCCESS`)
- **Cancel button (✗)**: Error red (`AppColors.ERROR`)

Display area:
- **Valid state**: Blue text on white background
- **Error state**: Red text on white background
- **Height**: 60px per button, custom display area at top

## Integration Notes

- The component uses `@Consume` for callbacks, requiring parent to use `@Provide`
- Parent is responsible for final business logic validation
- Component performs only essential format validation
- Error messages support both component-generated and parent-provided messages
- The component is fully reusable and maintains no external state dependencies

## Testing Checklist

When integrating this component, verify:
- [ ] Digit entry (0-9) works correctly
- [ ] Decimal point entry works (single only)
- [ ] Leading zero handling works as expected
- [ ] Delete removes last character
- [ ] Clear resets input and error messages
- [ ] Confirm validates and calls callback
- [ ] Cancel calls callback and clears input
- [ ] Error messages display correctly
- [ ] Disabled state prevents interactions
- [ ] Custom error messages from parent display properly
- [ ] Callbacks fire in correct order
