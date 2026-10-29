# RARFlow — The Ultimate Native macOS Archive & Compression Suite

**RARFlow** is a native, modern macOS application designed from the ground up for macOS Sequoia & Sonoma. It provides full inspection, extraction, and compression of RAR archives alongside all major formats (7-Zip, ZIP, TAR, GZIP, BZIP2, XZ, ISO, DMG) with zero external dependencies.

![RARFlow Icon](build/AppIcon.iconset/icon_128x128@2x.png)

---

## ✨ Features

### 🖱️ Finder Right-Click Context Menu & Quick Actions
- **"Extract using RARFlow"**: Right-click any archive in Finder to extract it or open the smart action prompt.
- **"Compress using RARFlow"**: Right-click any file(s) or folder(s) in Finder to compress them into RAR, 7Z, ZIP, or TAR.
- Native `NSServices` integration + Automator Quick Action workflows in `~/Library/Services/`.

### 🗄️ Full RAR Extraction & Support
- **Universal RAR Support**: Compatible with RAR 1.5, 2.0, 3.0, 4.x, 5.x, and RAR 7.x archives.
- **Encrypted Archives**: Full AES-256 password-protected archive opening and extraction.
- **Multi-Part / Split Volumes**: Automatically detects and extracts split `.part1.rar` and `.r00` volumes.
- **Solid Archives**: Full support for solid archives with high compression efficiency.

### ⚡ Comprehensive Compression Software Specifications
- **Multi-Format Creation**:
  - **RAR** (via bundled RARLAB engine)
  - **7-Zip (.7z)**
  - **ZIP (.zip)**
  - **TAR (.tar)**
  - **GZip Tarball (.tar.gz)**
  - **BZip2 Tarball (.tar.bz2)**
  - **XZ Tarball (.tar.xz)**
- **Compression Levels**: Store (0), Fastest (1), Fast (3), Normal (5), Maximum (7), Ultra (9).
- **Compression Algorithms**: LZMA2, LZMA, Deflate, Deflate64, BZip2, PPMd.
- **AES-256 Encryption & Header Hiding**: Password-protect your archives and optionally encrypt file headers (`-mhe=on`) so file names cannot be seen without entering the password.
- **Split Multi-Volume Archives**: Split archives by custom MB sizes or standard media presets (10MB, 100MB, 700MB CD, 1GB, 4GB FAT32 limit, 4.7GB DVD, 25GB Blu-Ray).
- **macOS Metadata Stripping**: Clean `.DS_Store`, `__MACOSX`, `.Trashes`, `.Spotlight-V100`, and `._*` resource forks to prevent clutter when sending archives to Windows and Linux users.
- **Multithreading**: Automatic hardware detection to utilize all Apple Silicon performance cores.
- **Solid Compression**: Bundle similar files for maximum compression ratio.
- **Source File Cleanup**: Option to delete source files after compression.

### 🖥️ Native macOS Interface & User Experience
- **Interactive File Browser**: Detailed table view with file icons, uncompressed size, packed size, compression ratio %, modification date, and CRC32 checksums.
- **Quick Look Integration**: Press **Spacebar** on any file in an archive to immediately preview photos, text, PDFs, audio, and videos without extracting the entire archive to disk.
- **Quick Drop Zone**: Drag and drop any archive to extract instantly, or drop files/folders to launch the compression wizard in one click.
- **Hierarchical & Flat Modes**: Navigate folders level-by-level with breadcrumb navigation or switch to a flat list of all files.
- **Real-Time Search**: Filter thousands of files within large archives instantly.
- **Integrity Testing**: Built-in archive validation and checksum verification (`Cmd+T`).
- **Finder Drag & Drop**: Drag files directly from the archive window into any Finder folder.

---

## 🚀 Building & Packaging

### Prerequisites
- macOS 14.0 or newer (Apple Silicon / arm64)
- Swift 6.0+ / Xcode 16+

### 1. Build the Standalone `.app`
```bash
./scripts/build_app.sh
```
This builds `build/RARFlow.app` with bundled helper engines (`7zz`, `rar`, `unrar`, `unar`, `lsar`), retina `AppIcon.icns`, `NSServices`, Finder Quick Actions, and ad-hoc code signing.

### 2. Create the Distribution `.dmg`
```bash
./scripts/create_dmg.sh
```
Creates `build/RARFlow.dmg` containing `RARFlow.app` and an `/Applications` shortcut.

### 3. Run Automated Tests
```bash
swift test
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘ + O` | Open Archive File |
| `⌘ + N` | New Archive (Compress Files) |
| `⌘ + E` | Extract All Files |
| `⌘ + T` | Test Archive Integrity |
| `Space` | Quick Look Preview Selected File |
| `⌘ + ,` | Preferences / Settings |

---

## 📄 License
RARFlow is provided under the MIT License.
Bundled engines include 7-Zip (LGPL / BSD-3) and RAR/UNRAR (freeware from RARLAB).
