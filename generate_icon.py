# generate_icon.py
# Generates the Vynex app icon: gold V on black background.
# Run with: python generate_icon.py
# Requires: pip install Pillow

from PIL import Image, ImageDraw
import os

SIZE = 1024
GOLD = (255, 215, 0)
BLACK = (26, 26, 26)

img = Image.new('RGB', (SIZE, SIZE), BLACK)
draw = ImageDraw.Draw(img)

# Draw rounded rectangle background (simulate rounded icon)
margin = 80
draw.rounded_rectangle(
    [margin, margin, SIZE - margin, SIZE - margin],
    radius=120,
    fill=GOLD,
)

# Draw inner black rounded rectangle
inner_margin = 110
draw.rounded_rectangle(
    [inner_margin, inner_margin,
     SIZE - inner_margin, SIZE - inner_margin],
    radius=100,
    fill=BLACK,
)

# Draw the V shape using polygon
top_y = 260
bottom_y = 740
left_x = 200
right_x = 824
center_x = 512
line_width = 90

draw.polygon([
    (left_x, top_y),
    (left_x + line_width, top_y),
    (center_x + line_width // 2, bottom_y),
    (center_x - line_width // 2, bottom_y),
], fill=GOLD)

draw.polygon([
    (right_x - line_width, top_y),
    (right_x, top_y),
    (center_x + line_width // 2, bottom_y),
    (center_x - line_width // 2, bottom_y),
], fill=GOLD)

output_path = os.path.join('assets', 'icons', 'app_icon.png')
os.makedirs(os.path.dirname(output_path), exist_ok=True)
img.save(output_path, 'PNG')
print(f'Icon saved to {output_path}')

store_path = os.path.join('assets', 'icons', 'app_icon_store.png')
img.save(store_path, 'PNG')
print(f'Store icon saved to {store_path}')
