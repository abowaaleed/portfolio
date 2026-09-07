import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> pickImageAsBase64({int maxWidth = 600}) async {
  try {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return null;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(input.files![0]);
    await reader.onLoad.first;
    final bytes = reader.result as Uint8List;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrl(blob);
    final img = html.ImageElement();
    img.src = url;
    await img.onLoad.first;
    html.Url.revokeObjectUrl(url);
    final sw = img.width ?? 0;
    final sh = img.height ?? 0;
    if (sw == 0 || sh == 0) return null;
    int w = sw;
    int h = sh;
    if (w > maxWidth) {
      h = (h * maxWidth / w).round();
      w = maxWidth;
    }
    final canvas = html.CanvasElement();
    canvas.width = w;
    canvas.height = h;
    final ctx = canvas.context2D;
    ctx.drawImageScaled(img, 0, 0, w, h);
    final compressed = canvas.toDataUrl('image/webp', 0.7);
    return compressed;
  } catch (e) {
    return null;
  }
}
