#!/bin/bash
set -e

ABSEIL_VERSION="20260526.0"
ABSEIL_DIR="/tmp/abseil-cpp-src"
INSTALL_PREFIX="$HOME/.local"

if [ ! -f /usr/bin/AyuGram ]; then
    echo "Installing AyuGram package..."
    sudo pacman -U /home/sunraku/.cache/yay/ayugram-desktop-bin/ayugram-desktop-bin-6.7.8-7-x86_64.pkg.tar.zst --noconfirm
fi

if ! ldconfig -p | grep -q "libabsl_throw_delegate.so.2605"; then
    echo "Building abseil-cpp $ABSEIL_VERSION (shared libs)..."
    if [ ! -d "$ABSEIL_DIR" ]; then
        git clone --branch "$ABSEIL_VERSION" https://github.com/abseil/abseil-cpp.git "$ABSEIL_DIR"
    fi
    cmake -B "$ABSEIL_DIR/build-shared" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=ON \
        "$ABSEIL_DIR"
    cmake --build "$ABSEIL_DIR/build-shared" -j"$(nproc)"
    cmake --install "$ABSEIL_DIR/build-shared"
fi

# Fix wrapper script
cat > "$HOME/.local/bin/AyuGram-wrapper" << 'EOF'
#!/bin/bash
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="/tmp/qt6-imageformats-pkg/usr/lib/qt6/plugins:$QT_PLUGIN_PATH"
exec /usr/bin/AyuGram "$@"
EOF
chmod +x "$HOME/.local/bin/AyuGram-wrapper"

# Fix desktop file to use wrapper
echo 321q | sudo -S sed -i \
  's|TryExec=AyuGram|TryExec='"$HOME"'/.local/bin/AyuGram-wrapper|;
   s|Exec=env DESKTOPINTEGRATION=1 AyuGram -- %U|Exec='"$HOME"'/.local/bin/AyuGram-wrapper -- %U|;
   s|Exec=AyuGram -quit|Exec='"$HOME"'/.local/bin/AyuGram-wrapper -quit|' \
  /usr/share/applications/com.ayugram.desktop.desktop

echo "Launching AyuGram..."
"$HOME/.local/bin/AyuGram-wrapper" &