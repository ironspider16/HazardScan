import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO
from PIL import Image, ImageOps

app = Flask(__name__)
CORS(app)

model = YOLO("models/best.pt")

@app.route("/")
def home():
    return "HazardScan YOLO API is running"

@app.route("/detect", methods=["POST"])
def detect():
    if "image" not in request.files:
      return jsonify({"error": "No image uploaded"}), 400

    file = request.files["image"]

    img = Image.open(file.stream)
    img = ImageOps.exif_transpose(img)
    img = img.convert("RGB")

    print("Image type:", type(img), flush=True)
    print("Image shape:", img.size, flush=True)
    print("Filename:", file.filename, flush=True)
    print("Image size after EXIF:", img.size, flush=True)

    results = model.predict(img, imgsz=320, device="cpu", conf=0.25)
    # results = model.predict(img, imgsz=640, device="cpu", conf=0.20)
    
    print("Detections:", len(results[0].boxes), flush=True)

    detections = []

    for box in results[0].boxes:
        cls = int(box.cls[0])
        conf = float(box.conf[0])

        x1, y1, x2, y2 = box.xyxy[0]

        detections.append({
            "label": model.names[cls],
            "confidence": conf,
            "x1": float(x1),
            "y1": float(y1),
            "x2": float(x2),
            "y2": float(y2),
        })
    return jsonify({
      "detections": detections
    })
    
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)