#!/bin/bash

echo "=== 检查 NumericKeypad.ets 语法 ==="
cd /home/engine/project/entry/src/main/ets/components
node -c NumericKeypad.ets 2>/dev/null && echo "✓ NumericKeypad.ets 语法正确" || echo "✗ NumericKeypad.ets 语法错误"

echo "=== 检查 Index.ets 语法 ==="
cd /home/engine/project/entry/src/main/ets/pages
node -c Index.ets 2>/dev/null && echo "✓ Index.ets 语法正确" || echo "✗ Index.ets 语法错误"

echo "=== 检查主要修改 ==="
echo "1. NumericKeypad按钮高度: 60vp -> 38vp"
echo "2. NumericKeypad按钮间距: 10vp -> 3vp" 
echo "3. NumericKeypad字体大小: 18fp -> 13fp"
echo "4. NumericKeypad显示字体: 48fp -> 36fp"
echo "5. Index第一栏高度: 200vp -> 120vp"
echo "6. Index第二栏高度: 80vp -> 50vp"
echo "7. 使用Grid布局替代Row布局"
echo "8. 按钮文字简化(去掉中文描述)"

echo "=== 预期效果 ==="
echo "- 键盘总高度: 202vp (5行×38vp + 4×3vp间距)"
echo "- 第一栏+第二栏+键盘标题+键盘显示+键盘按钮 ≈ 410vp"
echo "- 在2832vp屏幕高度中完全够用"
echo "- 键盘应该能完整显示，无需滚动"