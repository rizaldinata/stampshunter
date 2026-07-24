import io
import pytest
from PIL import Image
from app.services.image_processor import ImageProcessor


def create_test_image(size=(100, 100), color=(255, 0, 0)) -> bytes:
    """Create a simple RGB image and return its bytes."""
    img = Image.new("RGB", size, color)
    out = io.BytesIO()
    img.save(out, format="JPEG")
    return out.getvalue()


def test_ensure_fonts():
    """Verify font directory initialization."""
    processor = ImageProcessor()
    assert os.path.exists(processor.fonts_dir)


def test_parse_hex_color():
    processor = ImageProcessor()
    assert processor._parse_hex_color("#FFFFFF") == (255, 255, 255)
    assert processor._parse_hex_color("#000") == (0, 0, 0)
    assert processor._parse_hex_color("invalid") == (255, 255, 255)


def test_apply_stamp_border():
    processor = ImageProcessor()
    img_bytes = create_test_image()
    img = Image.open(io.BytesIO(img_bytes))

    border_config = {
        "tooth_size": 10,
        "tooth_spacing": 5,
        "border_width": 20,
        "border_color": "#FFFFFF",
    }
    result = processor.apply_border(img, border_config)

    assert result.width == img.width + 40
    assert result.height == img.height + 40
    assert result.mode == "RGBA"


def test_apply_vintage_filter():
    processor = ImageProcessor()
    img_bytes = create_test_image()
    img = Image.open(io.BytesIO(img_bytes))

    filter_config = {
        "intensity": 0.8,
        "warmth": 0.5,
        "grain": 0.3,
        "vignette": 0.4,
        "sepia": 0.2,
    }
    result = processor.apply_filter(img, filter_config)

    assert result.size == img.size
    assert result.mode == "RGBA"


def test_apply_template():
    processor = ImageProcessor()
    img_bytes = create_test_image()
    img = Image.open(io.BytesIO(img_bytes))

    template_config = {
        "overlay_url": "/static/templates/mock_template.png",
        "frame_color": "#FF0000",
    }
    result = processor.apply_template(img, template_config)

    assert result.size == img.size
    assert result.mode == "RGBA"


def test_add_text_overlays():
    processor = ImageProcessor()
    img_bytes = create_test_image()
    img = Image.open(io.BytesIO(img_bytes))

    text_items = [
        {
            "content": "TEST STAMP",
            "position": "top",
            "font_family": "serif",
            "font_size": 12,
            "font_color": "#000000",
        }
    ]
    result = processor.add_text_overlays(img, text_items)

    assert result.size == img.size
    assert result.mode == "RGBA"


import os
