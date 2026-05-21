# from flask import Flask, request, jsonify
# from ultralytics import YOLO
# import cv2
# import numpy as np

# app = Flask(__name__)

# model = YOLO("models/my_model.pt")

# @app.route("/detect", methods=["POST"])
# def detect():

#     file = request.files["image"]

#     image_bytes = file.read()

#     npimg = np.frombuffer(image_bytes, np.uint8)

#     img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

#     results = model(img)

#     detections = []

#     for r in results:
#         for box in r.boxes:

#             cls = int(box.cls[0])
#             conf = float(box.conf[0])

#             detections.append({
#                 "class": model.names[cls],
#                 "confidence": conf
#             })

#     return jsonify(detections)

# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000)


import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO

app = Flask(__name__)
CORS(app)

model = YOLO("models/my_model.pt")

@app.route("/")
def home():
    return "HazardScan YOLO API is running"

@app.route("/detect", methods=["POST"])
def detect():
    image = request.files["image"]
    results = model(image.read())

    detections = []

    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            conf = float(box.conf[0])
            detections.append({
                "class": model.names[cls],
                "confidence": conf
            })

    return jsonify(detections)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)