from pathlib import Path

import numpy as np
from PIL import Image, ImageOps
from ai_edge_litert.interpreter import Interpreter


# ============================================================
# Paths
# ============================================================

ROOT = Path(__file__).resolve().parent

MODEL_PATH = (
    ROOT
    / "packages"
    / "minifasnet"
    / "assets"
    / "silentface.tflite"
)

IMAGE_PATH = (
    ROOT
    / "assets"
    / "test_images"
    / "image_T1.jpg"
)


# ============================================================
# Known T1 face bounding box from our ML Kit detection
# ============================================================

FACE_LEFT = 106.0
FACE_TOP = 118.0
FACE_RIGHT = 293.0
FACE_BOTTOM = 365.0


# ============================================================
# Crop implementation based on MiniVision CropImage
# ============================================================

def calculate_crop(
    left,
    top,
    right,
    bottom,
    image_width,
    image_height,
    scale,
):
    face_width = right - left
    face_height = bottom - top

    actual_scale = min(
        (image_height - 1) / face_height,
        (image_width - 1) / face_width,
        scale,
    )

    new_width = face_width * actual_scale
    new_height = face_height * actual_scale

    center_x = face_width / 2 + left
    center_y = face_height / 2 + top

    crop_left = center_x - new_width / 2
    crop_top = center_y - new_height / 2
    crop_right = center_x + new_width / 2
    crop_bottom = center_y + new_height / 2

    # Shift entire crop back inside image.
    if crop_left < 0:
        crop_right -= crop_left
        crop_left = 0

    if crop_top < 0:
        crop_bottom -= crop_top
        crop_top = 0

    if crop_right > image_width - 1:
        crop_left -= crop_right - image_width + 1
        crop_right = image_width - 1

    if crop_bottom > image_height - 1:
        crop_top -= crop_bottom - image_height + 1
        crop_bottom = image_height - 1

    return (
        round(crop_left),
        round(crop_top),
        round(crop_right - crop_left + 1),
        round(crop_bottom - crop_top + 1),
    )


# ============================================================
# Load model
# ============================================================

print("Loading model...")
print(MODEL_PATH)

interpreter = Interpreter(
    model_path=str(MODEL_PATH),
)

interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print()
print("Model input:")
print(" shape:", input_details[0]["shape"])
print(" dtype:", input_details[0]["dtype"])

print()
print("Model output:")
print(" shape:", output_details[0]["shape"])
print(" dtype:", output_details[0]["dtype"])


# ============================================================
# Load source image
# ============================================================

image = Image.open(IMAGE_PATH)

print()
print("Original JPEG:")
print(f" {image.size}")
print(f" EXIF orientation: {image.getexif().get(274)}")

image = ImageOps.exif_transpose(image).convert("RGB")

print()
print("After EXIF orientation:")
print(f" {image.size}")

image_width, image_height = image.size

print()
print("Source image:")
print(f" {image_width} × {image_height}")

print()
print("Face box:")
print(
    f" left={FACE_LEFT}, "
    f"top={FACE_TOP}, "
    f"right={FACE_RIGHT}, "
    f"bottom={FACE_BOTTOM}"
)


# ============================================================
# Test different crop scales
# ============================================================

scales = [
    1.0,
    1.5,
    2.0,
    2.7,
    3.5,
    4.0,
]


print()
print("=" * 80)
print("MiniFASNet crop-scale experiment")
print("=" * 80)

print()
print(
    f"{'Scale':>7} "
    f"{'Crop':>15} "
    f"{'Print':>12} "
    f"{'Live':>12} "
    f"{'Replay':>12} "
    f"{'Class':>10}"
)

print("-" * 80)


for scale in scales:

    # --------------------------------------------------------
    # Calculate crop
    # --------------------------------------------------------

    x, y, width, height = calculate_crop(
        FACE_LEFT,
        FACE_TOP,
        FACE_RIGHT,
        FACE_BOTTOM,
        image_width,
        image_height,
        scale,
    )

    # --------------------------------------------------------
    # Crop
    # --------------------------------------------------------

    crop = image.crop(
        (
            x,
            y,
            x + width,
            y + height,
        )
    )

    # --------------------------------------------------------
    # Resize to 80 × 80
    # --------------------------------------------------------

    resized = crop.resize(
        (80, 80),
        Image.Resampling.BILINEAR,
    )

    # --------------------------------------------------------
    # RGB -> float32 [0,1]
    # --------------------------------------------------------

    rgb = np.asarray(
        resized,
        dtype=np.float32,
    ) / 255.0

    # --------------------------------------------------------
    # RGB -> BGR
    # --------------------------------------------------------

    bgr = rgb[:, :, ::-1]

    # --------------------------------------------------------
    # HWC -> NCHW
    # --------------------------------------------------------

    tensor = np.transpose(
        bgr,
        (2, 0, 1),
    )[None, ...]

    # --------------------------------------------------------
    # Run model
    # --------------------------------------------------------

    interpreter.set_tensor(
        input_details[0]["index"],
        tensor.astype(np.float32),
    )

    interpreter.invoke()

    output = interpreter.get_tensor(
        output_details[0]["index"]
    )[0]

    print_score = float(output[0])
    live_score = float(output[1])
    replay_score = float(output[2])

    predicted_class = int(np.argmax(output))

    labels = [
        "print",
        "live",
        "replay",
    ]

    print(
        f"{scale:>7.1f} "
        f"{width:>4}x{height:<10} "
        f"{print_score:>12.6f} "
        f"{live_score:>12.6f} "
        f"{replay_score:>12.6f} "
        f"{labels[predicted_class]:>10}"
    )

    # --------------------------------------------------------
    # Save crop for visual inspection
    # --------------------------------------------------------

    crop_path = (
        ROOT
        / f"debug_T1_scale_{scale:.1f}x.jpg"
    )

    crop.save(
        crop_path,
        quality=95,
    )


print()
print("=" * 80)
print("Done.")
print("Debug crops were saved in the project root.")
print("=" * 80)
