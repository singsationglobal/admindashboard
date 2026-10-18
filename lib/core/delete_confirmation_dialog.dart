import 'package:flutter/material.dart';
import 'admin_theme.dart';

Future<bool> showPermanentDeleteConfirmation(BuildContext context, String itemName) async {
  final TextEditingController controller = TextEditingController();
  bool isValid = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        title: const Text('Permanently Delete?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "$itemName"? This action cannot be undone.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text('Type "delete" to confirm:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              // ✅ FORCED BLACK TEXT AND CURSOR SO IT IS ALWAYS VISIBLE
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                hintText: 'delete',
                hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                // ✅ FORCED PURE WHITE BACKGROUND
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
              ),
              onChanged: (value) {
                setState(() {
                  isValid = value.trim().toLowerCase() == 'delete';
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: isValid ? () => Navigator.pop(context, true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? Colors.red : Colors.grey,
            ),
            child: const Text('PERMANENTLY DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}
