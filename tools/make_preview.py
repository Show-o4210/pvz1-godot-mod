"""Make a compact animated preview from Godot-rendered verification frames."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
paths = sorted((root / 'build' / 'v1-frames').glob('*.png'))
if len(paths) != 160:
    raise SystemExit(f'Expected 160 completed frames, found {len(paths)}')
frames = [Image.open(path).convert('RGB').resize((800, 600), Image.Resampling.LANCZOS)
          for path in paths]
# One palette keeps colors stable between frames and permits GIF frame differencing.
sample = Image.new('RGB', (800, 600 * 8))
for i in range(8):
    sample.paste(frames[i * 20], (0, 600 * i))
palette = sample.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.FLOYDSTEINBERG) for frame in frames]
output = root / 'build' / 'v1-preview.gif'
indexed[0].save(output, save_all=True, append_images=indexed[1:],
                duration=50, loop=0, optimize=True, disposal=1)
print(f'{len(indexed)} frames, {output.stat().st_size / 1048576:.2f} MiB: {output}')
