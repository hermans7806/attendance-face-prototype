from pathlib import Path

import numpy as np
from PIL import Image
from ai_edge_litert.interpreter import Interpreter


# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent

MODEL_PATH = (
    PROJECT_ROOT
    / "packages"
    / "minifasnet"
    / "assets"
    / "silentface.tflite"
)

IMAGE_PATH = (
    PROJECT_ROOT
    / "minifas_80x80_input.png"
)


# ------------------------------------------------------------
# Load image
# ------------------------------------------------------------

print("Loading image:")
print(IMAGE_PATH)

img = Image.open(IMAGE_PATH).convert("RGB")

print(f"Image size: {img.size}")


# ------------------------------------------------------------
# RGB image -> float32 [0, 1]
# ------------------------------------------------------------

rgb = np.asarray(
    img,
    dtype=np.float32,
) / 255.0


# ------------------------------------------------------------
# RGB -> BGR
# ------------------------------------------------------------

bgr = rgb[:, :, ::-1]


# ------------------------------------------------------------
# HWC -> NCHW
#
# Flutter:
# [1, 3, 80, 80]
# ------------------------------------------------------------

x = np.transpose(
    bgr,
    (2, 0, 1),
)[None, ...]


print()
print("Input tensor:")
print(f"  shape : {x.shape}")
print(f"  dtype : {x.dtype}")
print(f"  min   : {x.min()}")
print(f"  max   : {x.max()}")
print(f"  mean  : {x.mean()}")
print(f"  count : {x.size}")

print()
print("Tensor sample:")
print(
    f"  C0={x[0, 0, 40, 40]:.6f}, "
    f"C1={x[0, 1, 40, 40]:.6f}, "
    f"C2={x[0, 2, 40, 40]:.6f}"
)


# ------------------------------------------------------------
# Load model
# ------------------------------------------------------------

print()
print("Loading model:")
print(MODEL_PATH)

interpreter = Interpreter(
    model_path=str(MODEL_PATH),
)

interpreter.allocate_tensors()


# ------------------------------------------------------------
# Inspect model tensors
# ------------------------------------------------------------

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print()
print("Model input:")
print(input_details[0])

print()
print("Model output:")
print(output_details[0])


# ------------------------------------------------------------
# Run inference
# ------------------------------------------------------------

interpreter.set_tensor(
    input_details[0]["index"],
    x.astype(np.float32),
)

interpreter.invoke()


# ------------------------------------------------------------
# Get raw output
# ------------------------------------------------------------

output = interpreter.get_tensor(
    output_details[0]["index"]
)[0]

print()
print("RAW OUTPUT:")
print(output)


# ------------------------------------------------------------
# Output
#
# 0 = print
# 1 = live
# 2 = replay
# ------------------------------------------------------------

print()
print("RESULT:")
print(f"  print : {output[0]:.10f}")
print(f"  live  : {output[1]:.10f}")
print(f"  replay: {output[2]:.10f}")

predicted = int(np.argmax(output))

labels = [
    "print",
    "live",
    "replay",
]

print()
print(f"Predicted class: {predicted} ({labels[predicted]})")
