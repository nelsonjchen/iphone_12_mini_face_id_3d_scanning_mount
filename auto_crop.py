from PIL import Image, ImageChops

def crop_image(image_path):
    print(f"Processing {image_path}...")
    try:
        img = Image.open(image_path)
        
        # Assume top-left pixel is the background color
        bg = Image.new(img.mode, img.size, img.getpixel((0,0)))
        
        # Create a difference image
        diff = ImageChops.difference(img, bg)
        
        # Get the bounding box of the non-zero difference regions
        # (add=True means we treat the diff as a mask where non-zero is content)
        diff = ImageChops.add(diff, diff, 2.0, -100) # Enhance contrast to catch faint shadows
        bbox = diff.getbbox()
        
        if bbox:
            print(f"  Found content at {bbox}")
            # Add a small padding
            padding = 20
            left, upper, right, lower = bbox
            left = max(0, left - padding)
            upper = max(0, upper - padding)
            right = min(img.width, right + padding)
            lower = min(img.height, lower + padding)
            
            cropped = img.crop((left, upper, right, lower))
            cropped.save(image_path)
            print(f"  Cropped and saved to {image_path}")
        else:
            print("  No content found (image matches background entirely?)")
            
    except Exception as e:
        print(f"  Error processing {image_path}: {e}")

if __name__ == "__main__":
    crop_image("hero.png")
    crop_image("hero_storage.png")
