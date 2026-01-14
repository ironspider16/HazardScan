// lib/services/yolo_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../models/detection.dart';

class _CropBox {
  final int x, y, w, h;
  const _CropBox(this.x, this.y, this.w, this.h);
}

class _LetterboxResult {
  final img.Image image640; // 640x640 padded image
  final double scale;       // resize scale applied to original
  final int padX;           // left pad in 640 space
  final int padY;           // top pad in 640 space
  const _LetterboxResult(this.image640, this.scale, this.padX, this.padY);
}

class YoloService {
  static OrtSession? _session;
  static const int inputSize = 640;

  // Must match your dataset YAML order exactly
  static const List<String> classNames = [
    'broken steps', // 0 hazard
    'ladder',       // 1 not hazard
    'locked',       // 2 hazard/status
    'scaffolding',  // 3 not hazard
    'unlocked',     // 4 hazard
  ];

  Future<void> _init() async {
    if (_session != null) return;

    OrtEnv.instance.init();

    final raw = await rootBundle.load('assets/models/best.onnx');
    final bytes = raw.buffer.asUint8List();

    final options = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, options);

    // ignore: avoid_print
    print('ONNX inputs: ${_session!.inputNames}');
    // ignore: avoid_print
    print('ONNX outputs: ${_session!.outputNames}');
  }

  /// Single pass on full image (letterboxed)
  Future<List<Detection>> detectOnImage(
    String imagePath, {
    double confThreshold = 0.25,
    double iouThreshold = 0.35,
  }) async {
    await _init();

    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return [];

    return _detectOnImgImageLetterbox(
      image,
      confThreshold: confThreshold,
      iouThreshold: iouThreshold,
    );
  }

  /// Best for your case: ladder first, then crop-and-zoom to detect tiny lock hazards.
  Future<List<Detection>> detectOnImageWithLadderCrop(
    String imagePath, {
    double ladderConf = 0.25,
    double hazardConf = 0.07, // try 0.08~0.12 for small hazards
    double iouThreshold = 0.35,
    double cropPadding = 0.25,
  }) async {
    await _init();

    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return [];

    final origW = original.width;
    final origH = original.height;

    // ----- PASS 1: detect ladder on full image -----
    final pass1 = await _detectOnImgImageLetterbox(
      original,
      confThreshold: ladderConf,
      iouThreshold: iouThreshold,
    );

    final ladders = pass1.where((d) => d.classId == 1).toList();
    if (ladders.isEmpty) return pass1;

    ladders.sort((a, b) => b.confidence.compareTo(a.confidence));
    final bestLadder = ladders.first;

    // ----- Crop around ladder in ORIGINAL image coords -----
    final crop = _makeCropFromDetection(
      bestLadder,
      origW,
      origH,
      padding: cropPadding,
    );

    final cropped = img.copyCrop(
      original,
      x: crop.x,
      y: crop.y,
      width: crop.w,
      height: crop.h,
    );

    // ----- PASS 2: detect hazards on ladder crop -----
final pass2 = await _detectOnImgImageLetterbox(
  cropped,
  confThreshold: hazardConf,
  iouThreshold: iouThreshold,
);

// ----- PASS 3: side crops (LEFT + RIGHT) -----
final leftSide = _sideCrop(crop, true);
final rightSide = _sideCrop(crop, false);

final leftImg = img.copyCrop(
  original,
  x: leftSide.x,
  y: leftSide.y,
  width: leftSide.w,
  height: leftSide.h,
);

final rightImg = img.copyCrop(
  original,
  x: rightSide.x,
  y: rightSide.y,
  width: rightSide.w,
  height: rightSide.h,
);

final leftDet = await _detectOnImgImageLetterbox(
  leftImg,
  confThreshold: hazardConf,
  iouThreshold: iouThreshold,
);

final rightDet = await _detectOnImgImageLetterbox(
  rightImg,
  confThreshold: hazardConf,
  iouThreshold: iouThreshold,
);

// ----- Collect ONLY unlocked hazards -----
final hazards = <Detection>[
  ...pass2,
  ...leftDet.map((d) => Detection(
        left: d.left + leftSide.x,
        top: d.top + leftSide.y,
        right: d.right + leftSide.x,
        bottom: d.bottom + leftSide.y,
        classId: d.classId,
        confidence: d.confidence,
      )),
  ...rightDet.map((d) => Detection(
        left: d.left + rightSide.x,
        top: d.top + rightSide.y,
        right: d.right + rightSide.x,
        bottom: d.bottom + rightSide.y,
        classId: d.classId,
        confidence: d.confidence,
      )),
]
   .where((d) => d.classId == 0 || d.classId == 4) // broken steps OR unlocked
 // 🔥 unlocked only
    .toList();

// Combine final output
final combined = <Detection>[
  bestLadder,
  ...hazards,
];

return _nms(combined, iouThreshold);

  }

  // =========================
  // Letterbox (matches Ultralytics)
  // =========================
  _LetterboxResult _letterbox(img.Image src, {int newSize = inputSize}) {
    final w = src.width;
    final h = src.height;

    final scale = min(newSize / w, newSize / h);
    final nw = (w * scale).round();
    final nh = (h * scale).round();

    final resized = img.copyResize(src, width: nw, height: nh);

    // 640x640 canvas with padding color 114 (Ultralytics default)
    final canvas = img.Image(width: newSize, height: newSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));

    final padX = ((newSize - nw) / 2).round();
    final padY = ((newSize - nh) / 2).round();

    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    return _LetterboxResult(canvas, scale, padX, padY);
  }

  // =========================
  // Core inference (LETTERBOXED)
  // Returns detections in ORIGINAL IMAGE PIXELS of that input image
  // =========================
  Future<List<Detection>> _detectOnImgImageLetterbox(
    img.Image image, {
    required double confThreshold,
    required double iouThreshold,
  }) async {
    final origW = image.width;
    final origH = image.height;

    // Letterbox to 640x640
    final lb = _letterbox(image, newSize: inputSize);
    final resized = lb.image640;

    // CHW float32 tensor [1,3,640,640]
    final Float32List input = Float32List(1 * 3 * inputSize * inputSize);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        input[pixelIndex] = p.r / 255.0;
        input[pixelIndex + inputSize * inputSize] = p.g / 255.0;
        input[pixelIndex + 2 * inputSize * inputSize] = p.b / 255.0;
        pixelIndex++;
      }
    }

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, inputSize, inputSize],
    );

    final outputs = _session!.run(
      OrtRunOptions(),
      {_session!.inputNames.first: inputTensor},
    );

    if (outputs.isEmpty || outputs.first == null) return [];
    final out = outputs.first!.value;
    if (out is! List) return [];

    final decoded = _decodeUltralyticsLetterbox(
      out,
      origW,
      origH,
      confThreshold,
      lb,
    );

    return _nms(decoded, iouThreshold);
  }

  // =========================
  // Decode output + map from 640 letterbox space -> original pixels
  // =========================
  List<Detection> _decodeUltralyticsLetterbox(
    List output,
    int origW,
    int origH,
    double confThreshold,
    _LetterboxResult lb,
  ) {
    final batch = output[0];

    final rows = _toRowMajor(batch);
    if (rows.isEmpty) return [];

    final nc = classNames.length;
    final dets = <Detection>[];

    final rowLen = rows[0].length;
    final hasObj = (rowLen == 5 + nc);
    final noObj = (rowLen == 4 + nc);

    // ignore: avoid_print
    print('YOLO rowLen=$rowLen (expected ${4 + nc} or ${5 + nc})');

    for (final r in rows) {
      if (r.length < 4 + nc) continue;

      // xywh in 640 letterbox space (usually)
      double cx = r[0];
      double cy = r[1];
      double w = r[2];
      double h = r[3];

      // Some exports output normalized (0..1). Convert to 640 if so.
      final normalized = cx <= 1.5 && cy <= 1.5 && w <= 1.5 && h <= 1.5;
      if (normalized) {
        cx *= inputSize;
        cy *= inputSize;
        w *= inputSize;
        h *= inputSize;
      }

      int classStart;
      double base;
      if (hasObj) {
        base = r[4];
        classStart = 5;
      } else if (noObj) {
        base = 1.0;
        classStart = 4;
      } else {
        // fallback guess
        base = r.length > 4 ? r[4] : 1.0;
        classStart = min(5, r.length);
      }

      int classId = 0;
      double bestClass = 0.0;

      final end = min(classStart + nc, r.length);
      for (int i = classStart; i < end; i++) {
        final p = r[i];
        if (p > bestClass) {
          bestClass = p;
          classId = i - classStart; // 0..nc-1
        }
      }

      final score = base * bestClass;
      if (score < confThreshold) continue;

      // Convert xywh -> xyxy in 640 space
      final left640 = cx - w / 2;
      final top640 = cy - h / 2;
      final right640 = cx + w / 2;
      final bottom640 = cy + h / 2;

      // Remove padding, then divide by scale to get original pixel coords
      final left = (left640 - lb.padX) / lb.scale;
      final top = (top640 - lb.padY) / lb.scale;
      final right = (right640 - lb.padX) / lb.scale;
      final bottom = (bottom640 - lb.padY) / lb.scale;

      // Clamp to image bounds
      final clLeft = left.clamp(0.0, origW.toDouble());
      final clTop = top.clamp(0.0, origH.toDouble());
      final clRight = right.clamp(0.0, origW.toDouble());
      final clBottom = bottom.clamp(0.0, origH.toDouble());

      if (clRight <= clLeft || clBottom <= clTop) continue;

      dets.add(
        Detection(
          left: clLeft,
          top: clTop,
          right: clRight,
          bottom: clBottom,
          classId: classId,
          confidence: score,
        ),
      );
    }

    return dets;
  }

  // =========================
  // Output to row-major [boxes][attrs]
  // =========================
  List<List<double>> _toRowMajor(dynamic batch) {
    if (batch is! List || batch.isEmpty) return [];
    if (batch[0] is! List) return [];

    final data = batch
        .map<List<double>>((row) =>
            (row as List).map((v) => (v as num).toDouble()).toList())
        .toList();

    final n = data.length;
    final m = data[0].length;

    // If shape looks like [attrs][boxes], transpose
    if (n <= 20 && m > 100) {
      final rows = m;
      final cols = n;
      return List.generate(rows, (i) => List.generate(cols, (c) => data[c][i]));
    }

    return data;
  }

  // =========================
  // NMS (class-wise)
  // =========================
  List<Detection> _nms(List<Detection> dets, double iouThreshold) {
    if (dets.isEmpty) return [];

    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final keep = <Detection>[];
    final suppressed = List<bool>.filled(dets.length, false);

    for (int i = 0; i < dets.length; i++) {
      if (suppressed[i]) continue;
      final a = dets[i];
      keep.add(a);

      for (int j = i + 1; j < dets.length; j++) {
        if (suppressed[j]) continue;
        final b = dets[j];

        if (a.classId != b.classId) continue;

        if (_iou(a, b) >= iouThreshold) suppressed[j] = true;
      }
    }

    return keep;
  }

  double _iou(Detection a, Detection b) {
    final xA = max(a.left, b.left);
    final yA = max(a.top, b.top);
    final xB = min(a.right, b.right);
    final yB = min(a.bottom, b.bottom);

    final interW = max(0.0, xB - xA);
    final interH = max(0.0, yB - yA);
    final interArea = interW * interH;

    final areaA = max(0.0, a.right - a.left) * max(0.0, a.bottom - a.top);
    final areaB = max(0.0, b.right - b.left) * max(0.0, b.bottom - b.top);

    final union = areaA + areaB - interArea;
    if (union <= 0) return 0.0;
    return interArea / union;
  }

  // =========================
  // Crop helper (original pixels)
  // =========================
  _CropBox _makeCropFromDetection(
    Detection d,
    int imageW,
    int imageH, {
    double padding = 0.20,
  }) {
    final boxW = (d.right - d.left).abs();
    final boxH = (d.bottom - d.top).abs();

    final padX = boxW * padding;
    final padY = boxH * padding;

    int x1 = (d.left - padX).floor();
    int y1 = (d.top - padY).floor();
    int x2 = (d.right + padX).ceil();
    int y2 = (d.bottom + padY).ceil();

    x1 = x1.clamp(0, imageW - 1);
    y1 = y1.clamp(0, imageH - 1);
    x2 = x2.clamp(0, imageW);
    y2 = y2.clamp(0, imageH);

    final w = max(1, x2 - x1);
    final h = max(1, y2 - y1);

    return _CropBox(x1, y1, w, h);
  }

  _CropBox _sideCrop(
  _CropBox ladder,
  bool leftSide, {
  double widthRatio = 0.35,
}) {
  final w = (ladder.w * widthRatio).round();
  final h = ladder.h;

  final x = leftSide ? ladder.x : ladder.x + ladder.w - w;
  final y = ladder.y;

  return _CropBox(x, y, w, h);
}

}
