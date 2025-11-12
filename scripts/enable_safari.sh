#!/bin/bash

echo "🔧 Enabling Safari for automation..."
echo ""
echo "This script will:"
echo "1. Enable safaridriver"
echo "2. Provide instructions for Safari settings"
echo ""

# Try to enable safaridriver
echo "Attempting to enable safaridriver (requires sudo/password)..."
sudo safaridriver --enable

if [ $? -eq 0 ]; then
    echo "✅ Safaridriver enabled successfully!"
else
    echo "❌ Failed to enable safaridriver"
    echo "Please run manually: sudo safaridriver --enable"
fi

echo ""
echo "⚠️  IMPORTANT: You must also enable 'Allow Remote Automation' in Safari:"
echo ""
echo "Manual steps:"
echo "1. Open Safari"
echo "2. If you don't see 'Develop' in the menu bar:"
echo "   - Go to Safari > Settings/Preferences (⌘,)"
echo "   - Click 'Advanced' tab"
echo "   - Check '☑ Show Develop menu in menu bar'"
echo "   - Close Settings"
echo "3. In the menu bar, click: Develop > Allow Remote Automation"
echo ""
echo "After completing these steps, run: bundle exec ruby create.rb"
