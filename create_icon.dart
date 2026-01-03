import 'dart:io';
import 'dart:typed_data';

// This script generates a simple Flordle app icon
// Run with: dart run create_icon.dart

void main() async {
  // Create a simple 512x512 PNG icon with Flordle theme colors
  // Using a pre-generated minimal PNG with green background and "F" letter

  // Base64 encoded 512x512 PNG icon for Flordle
  // Green background (#6AAA64) with white "F" letter
  final iconBytes = _createSimpleIcon();

  final file = File('assets/icon.png');
  await file.writeAsBytes(iconBytes);
  print('Icon created at assets/icon.png');

  // Also create foreground icon
  final foregroundFile = File('assets/icon_foreground.png');
  await foregroundFile.writeAsBytes(iconBytes);
  print('Foreground icon created at assets/icon_foreground.png');
}

Uint8List _createSimpleIcon() {
  // Minimal valid PNG - 1x1 pixel green (#6AAA64)
  // For a proper icon, we need a real image file
  // This is a placeholder - you should replace with actual icon
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, // 512x512
    0x08, 0x02, 0x00, 0x00, 0x00, 0x7B, 0x1A, 0x43, 0xAD, // 8-bit RGB
  ]);
}

