#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

# Create directory if it doesn't exist
os.makedirs('assets/images', exist_ok=True)

# Create a 96x96 image (2x for retina)
size = 96
image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

# Draw blue circle
center = size // 2
radius = size // 2

# Draw filled blue circle
draw.ellipse([0, 0, size-1, size-1], fill=(33, 150, 243, 255))  # #2196F3

# Draw white border
border_width = 6
draw.ellipse([border_width//2, border_width//2, size-border_width//2-1, size-border_width//2-1],
             outline=(255, 255, 255, 255), width=border_width)

# Save
image.save('assets/images/driver_marker.png')
print('✅ Driver marker created at assets/images/driver_marker.png')
