import io
import os
import urllib.request
from typing import Dict, List, Optional
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT_URLS = {
    "serif": "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Bold.ttf",
    "sans-serif": "https://github.com/google/fonts/raw/main/ofl/montserrat/static/Montserrat-SemiBold.ttf",
    "monospace": "https://github.com/google/fonts/raw/main/ofl/robotomono/static/RobotoMono-Regular.ttf",
    "readable": "https://github.com/google/fonts/raw/main/ofl/lora/static/Lora-Regular.ttf",
    "script": "https://github.com/google/fonts/raw/main/ofl/dancingscript/static/DancingScript-Regular.ttf"
}


class ImageProcessor:
    """Core stamp transformation engine."""

    def __init__(self, fonts_dir: str = "static/fonts"):
        self.fonts_dir = fonts_dir
        self._ensure_fonts()

    def _ensure_fonts(self):
        """Ensure required fonts are downloaded and saved in static/fonts/"""
        os.makedirs(self.fonts_dir, exist_ok=True)
        for font_name, url in FONT_URLS.items():
            font_path = os.path.join(self.fonts_dir, f"{font_name}.ttf")
            if not os.path.exists(font_path):
                try:
                    # Timeout after 5 seconds to prevent stalling server startup
                    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                    with urllib.request.urlopen(req, timeout=5.0) as response:
                        with open(font_path, "wb") as f:
                            f.write(response.read())
                    print(f"[ImageProcessor] Sukses mengunduh font {font_name}")
                except Exception as e:
                    print(f"[ImageProcessor] Gagal mengunduh font {font_name} (menggunakan fallback): {e}")

    def process(self, image_data: bytes, style: Dict) -> bytes:
        """Apply all effects based on style config."""
        img = Image.open(io.BytesIO(image_data))

        # 1. Normalize size (max 1024x1024 to save memory and processing time)
        max_size = 1024
        if img.width > max_size or img.height > max_size:
            img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

        # 2. Apply filter (vintage, sepia, etc)
        filter_config = style.get("filter")
        if filter_config and filter_config.get("enabled", True):
            img = self.apply_filter(img, filter_config.get("config", {}))

        # 3. Apply template overlay
        template_config = style.get("template")
        if template_config and template_config.get("enabled", False):
            img = self.apply_template(img, template_config)

        # 4. Add text overlays
        text_config = style.get("text")
        if text_config and text_config.get("enabled", True):
            img = self.add_text_overlays(img, text_config.get("items", []))

        # 5. Apply stamp border (Must be applied last to wrap everything inside the border)
        border_config = style.get("border")
        if border_config and border_config.get("enabled", True):
            img = self.apply_border(img, border_config.get("config", {}))

        # Convert to bytes
        output = io.BytesIO()
        # Always output as PNG to support transparent border perforations
        img.save(output, format="PNG", quality=95)
        return output.getvalue()

    def _parse_hex_color(self, hex_color: str, default=(255, 255, 255)) -> tuple:
        """Parse hex color string (e.g. #FFFFFF or #FFF) to RGB tuple."""
        if not hex_color or not hex_color.startswith("#"):
            return default
        try:
            hex_color = hex_color.lstrip("#")
            if len(hex_color) == 3:
                hex_color = "".join([c * 2 for c in hex_color])
            return int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
        except Exception:
            return default

    def apply_border(self, image: Image.Image, config: Dict) -> Image.Image:
        """Apply classic stamp border with teeth (perforated) effect."""
        tooth_size = int(config.get("tooth_size", 10))
        tooth_spacing = int(config.get("tooth_spacing", 5))
        border_width = int(config.get("border_width", 20))
        border_color_hex = config.get("border_color", "#FFFFFF")
        
        border_color = self._parse_hex_color(border_color_hex, (255, 255, 255))

        # Create new canvas with border padding
        new_width = image.width + border_width * 2
        new_height = image.height + border_width * 2
        result = Image.new("RGBA", (new_width, new_height), border_color + (255,))

        # Convert original image to RGBA if needed
        if image.mode != "RGBA":
            image = image.convert("RGBA")

        # Paste original image onto the center of the border canvas
        result.paste(image, (border_width, border_width), image)

        # Create alpha mask for the teeth perforation
        mask = Image.new("L", (new_width, new_height), 255)
        draw = ImageDraw.Draw(mask)

        # Draw elipses along horizontal edges (top and bottom)
        step = max(4, tooth_spacing * 2)
        for x in range(0, new_width, step):
            # Top edge
            draw.ellipse(
                [x - tooth_size // 2, -tooth_size // 2, x + tooth_size // 2, tooth_size // 2],
                fill=0,
            )
            # Bottom edge
            draw.ellipse(
                [
                    x - tooth_size // 2,
                    new_height - tooth_size // 2,
                    x + tooth_size // 2,
                    new_height + tooth_size // 2,
                ],
                fill=0,
            )

        # Draw elipses along vertical edges (left and right)
        for y in range(0, new_height, step):
            # Left edge
            draw.ellipse(
                [-tooth_size // 2, y - tooth_size // 2, tooth_size // 2, y + tooth_size // 2],
                fill=0,
            )
            # Right edge
            draw.ellipse(
                [
                    new_width - tooth_size // 2,
                    y - tooth_size // 2,
                    new_width + tooth_size // 2,
                    y + tooth_size // 2,
                ],
                fill=0,
            )

        # Apply the alpha mask to the image
        alpha = result.getchannel("A")
        from PIL import ImageChops
        new_alpha = ImageChops.multiply(alpha, mask)
        result.putalpha(new_alpha)

        return result

    def apply_filter(self, image: Image.Image, config: Dict) -> Image.Image:
        """Apply vintage/retro color grading, grain, warmth, and sepia."""
        intensity = float(config.get("intensity", 0.7))
        warmth = float(config.get("warmth", 0.5))
        grain = float(config.get("grain", 0.3))
        vignette = float(config.get("vignette", 0.4))
        sepia = float(config.get("sepia", 0.0))

        # Ensure RGBA, but process only RGB channels
        if image.mode != "RGBA":
            image = image.convert("RGBA")

        alpha = image.getchannel("A")
        rgb_image = image.convert("RGB")
        img_array = np.array(rgb_image, dtype=np.float64)

        # 1. Color grading (lift shadows, lower highlights)
        img_array = np.clip(img_array * 0.9 + 20 * intensity, 0, 255)

        # 2. Apply Sepia
        if sepia > 0:
            r = img_array[:, :, 0]
            g = img_array[:, :, 1]
            b = img_array[:, :, 2]

            tr = r * 0.393 + g * 0.769 + b * 0.189
            tg = r * 0.349 + g * 0.686 + b * 0.168
            tb = r * 0.272 + g * 0.534 + b * 0.131

            sepia_array = np.stack([tr, tg, tb], axis=-1)
            img_array = img_array * (1 - sepia) + sepia_array * sepia
            img_array = np.clip(img_array, 0, 255)

        # 3. Apply Warmth
        if warmth > 0:
            img_array[:, :, 0] = np.clip(img_array[:, :, 0] + (warmth * 25 * intensity), 0, 255)  # R
            img_array[:, :, 1] = np.clip(img_array[:, :, 1] + (warmth * 12 * intensity), 0, 255)  # G
            img_array[:, :, 2] = np.clip(img_array[:, :, 2] - (warmth * 18 * intensity), 0, 255)  # B

        # 4. Apply Grain/Noise
        if grain > 0:
            noise = np.random.normal(0, grain * 25 * intensity, img_array.shape)
            img_array = np.clip(img_array + noise, 0, 255)

        # 5. Apply Vignette
        if vignette > 0:
            rows, cols = img_array.shape[:2]
            X = np.arange(cols)
            Y = np.arange(rows)
            X, Y = np.meshgrid(X, Y)
            center_x, center_y = cols // 2, rows // 2
            distance = np.sqrt((X - center_x) ** 2 + (Y - center_y) ** 2)
            max_distance = np.sqrt(center_x ** 2 + center_y ** 2)
            vignette_mask = 1 - (distance / max_distance) * vignette * intensity
            vignette_mask = np.clip(vignette_mask, 0, 1)
            vignette_mask = np.stack([vignette_mask] * 3, axis=-1)
            img_array = img_array * vignette_mask

        # Blend with original
        original = np.array(rgb_image, dtype=np.float64)
        result = img_array * intensity + original * (1 - intensity)
        result = np.clip(result, 0, 255).astype(np.uint8)

        processed_rgb = Image.fromarray(result)
        processed_rgba = processed_rgb.convert("RGBA")
        processed_rgba.putalpha(alpha)

        return processed_rgba

    def apply_template(self, image: Image.Image, template_config: Dict) -> Image.Image:
        """Apply template overlay to image."""
        overlay_url = template_config.get("overlay_url")
        if not overlay_url:
            return image

        overlay_img = None
        if overlay_url.startswith("http://") or overlay_url.startswith("https://"):
            try:
                import httpx
                resp = httpx.get(overlay_url, timeout=5.0)
                if resp.status_code == 200:
                    overlay_img = Image.open(io.BytesIO(resp.content)).convert("RGBA")
            except Exception as e:
                print(f"[ImageProcessor] Gagal mendownload template overlay: {e}")

        if overlay_img is None:
            # Try to read local fallback
            local_path = overlay_url.replace("/static/", "static/")
            if os.path.exists(local_path):
                try:
                    overlay_img = Image.open(local_path).convert("RGBA")
                except Exception:
                    pass

        if overlay_img is None:
            # Visual fallback vector overlay
            overlay_img = Image.new("RGBA", image.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(overlay_img)
            frame_color_hex = template_config.get("frame_color", "#87CEEB")
            frame_color = self._parse_hex_color(frame_color_hex, (135, 206, 235))
            
            w, h = image.width, image.height
            # Draw elegant stamp inner frame border
            draw.rectangle([10, 10, w - 10, h - 10], outline=frame_color + (120,), width=6)
            # Corner accents
            draw.rectangle([10, 10, 30, 30], fill=frame_color + (120,))
            draw.rectangle([w - 30, 10, w - 10, 30], fill=frame_color + (120,))
            draw.rectangle([10, h - 30, 30, h - 10], fill=frame_color + (120,))
            draw.rectangle([w - 30, h - 30, w - 10, h - 10], fill=frame_color + (120,))

        # Resize overlay to match original
        overlay_img = overlay_img.resize(image.size, Image.Resampling.LANCZOS)

        if image.mode != "RGBA":
            image = image.convert("RGBA")

        return Image.alpha_composite(image, overlay_img)

    def add_text_overlays(self, image: Image.Image, items: List[Dict]) -> Image.Image:
        """Add multiple text overlays to image."""
        if not items:
            return image

        # Ensure image is editable
        if image.mode != "RGBA":
            image = image.convert("RGBA")

        # Create overlay layer for drawing text
        text_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(text_layer)

        for item in items:
            content = item.get("content", "")
            if not content:
                continue

            position = item.get("position", "bottom")
            font_family = item.get("font_family", "serif")
            font_size = int(item.get("font_size", 24))
            font_color_hex = item.get("font_color", "#000000")
            font_color = self._parse_hex_color(font_color_hex, (0, 0, 0))
            margin = int(item.get("margin", 20))

            # Resolve font
            font_path = os.path.join(self.fonts_dir, f"{font_family}.ttf")
            try:
                if os.path.exists(font_path):
                    font = ImageFont.truetype(font_path, font_size)
                else:
                    font = ImageFont.load_default()
            except Exception:
                font = ImageFont.load_default()

            # Get text bounding box
            text_bbox = draw.textbbox((0, 0), content, font=font)
            text_width = text_bbox[2] - text_bbox[0]
            text_height = text_bbox[3] - text_bbox[1]

            # Calculate coordinates
            w, h = image.width, image.height
            if position == "top":
                x = (w - text_width) // 2
                y = margin
            elif position == "bottom":
                x = (w - text_width) // 2
                y = h - text_height - margin - 5
            elif position == "left":
                x = margin
                y = (h - text_height) // 2
            elif position == "right":
                x = w - text_width - margin
                y = (h - text_height) // 2
            elif position == "center":
                x = (w - text_width) // 2
                y = (h - text_height) // 2
            else:
                x = (w - text_width) // 2
                y = h - text_height - margin

            # Add high-contrast drop shadow for legibility
            shadow_color = (255, 255, 255, 180) if sum(font_color) < 380 else (0, 0, 0, 180)
            draw.text((x + 1, y + 1), content, font=font, fill=shadow_color)
            draw.text((x, y), content, font=font, fill=font_color + (255,))

        # Composite text layer onto image
        return Image.alpha_composite(image, text_layer)

    def generate_thumbnail(self, image_data: bytes, size=(400, 400)) -> bytes:
        """Generate thumbnail from processed image bytes."""
        img = Image.open(io.BytesIO(image_data))
        # Ensure aspect ratio is maintained or cropped to square
        img_thumb = img.copy()
        img_thumb.thumbnail(size, Image.Resampling.LANCZOS)
        
        output = io.BytesIO()
        img_thumb.save(output, format="PNG")
        return output.getvalue()
