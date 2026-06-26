import os
import tarfile
import shutil

workspace_dir = os.path.dirname(os.path.abspath(__file__))
exports_dir = os.path.join(workspace_dir, "exports")
temp_dir = os.path.join(workspace_dir, "linux_setup_tmp")
tar_path = os.path.join(workspace_dir, "payload.tar.gz")
installer_path = os.path.join(exports_dir, "ranotot_linux_setup.sh")

linux_bin = os.path.join(exports_dir, "ranotot_linux.x86_64")
icon_src = os.path.join(workspace_dir, "icon.svg")

# 1. Clean temp directory
if os.path.exists(temp_dir):
    shutil.rmtree(temp_dir)
os.makedirs(temp_dir)

# 2. Copy files to package
shutil.copy2(linux_bin, os.path.join(temp_dir, "ranotot_linux.x86_64"))
shutil.copy2(icon_src, os.path.join(temp_dir, "icon.svg"))

# 3. Create tarball
with tarfile.open(tar_path, "w:gz") as tar:
    tar.add(temp_dir, arcname="ranotot")

# 4. Read tarball data
with open(tar_path, "rb") as f:
    tar_data = f.read()

# 5. Define installer script header
header = """#!/bin/bash
# self-extracting installer for ranotot
echo "=========================================="
echo "    ranotot Linux Installer"
echo "=========================================="

INSTALL_DIR="$HOME/.local/share/ranotot"
echo "Installing to $INSTALL_DIR..."

mkdir -p "$INSTALL_DIR"

# Find payload boundary
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")

# Extract tarball payload
tail -n +$PAYLOAD_LINE "$0" | tar -xzf - -C "$INSTALL_DIR" --strip-components=1

# Make binary executable
chmod +x "$INSTALL_DIR/ranotot_linux.x86_64"

# Create applications folder and desktop shortcut
mkdir -p "$HOME/.local/share/applications"
cat <<EOF > "$HOME/.local/share/applications/ranotot.desktop"
[Desktop Entry]
Name=ranotot
Comment=Hop on your scooter and become the galaxy's craziest delivery driver!
Exec=$INSTALL_DIR/ranotot_linux.x86_64
Icon=$INSTALL_DIR/icon.svg
Terminal=false
Type=Application
Categories=Game;
EOF

echo "ranotot installed successfully!"
echo "You can find and launch ranotot from your Applications menu."
echo "=========================================="
exit 0
__PAYLOAD_BELOW__
"""

# 6. Write final self-extracting installer script
with open(installer_path, "wb") as f:
    f.write(header.encode("utf-8"))
    f.write(tar_data)

# 7. Make the installer executable locally too
os.chmod(installer_path, 0o755)

print(f"Self-extracting installer successfully created at: {installer_path}")
print(f"Size: {os.path.getsize(installer_path) / (1024*1024):.2f} MB")

# Clean up
if os.path.exists(temp_dir):
    shutil.rmtree(temp_dir)
if os.path.exists(tar_path):
    os.remove(tar_path)
