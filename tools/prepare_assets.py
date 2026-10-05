"""Import the minimal game's art from a local PvZ installation.

Usage: python tools/prepare_assets.py path/to/original/game
Community converter: https://github.com/ec50n9/pvz2godot (GPL-3.0).
"""
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'pvz2godot'))
from unpack_pak import unpack_pak
from convert import convert
from reanim_parse import parse_reanim, split_labels


def prepare(game_dir: Path):
    extracted = ROOT / '.source_assets'
    unpack_pak(str(game_dir / 'main.pak'), str(extracted))
    # External files override packed files in this local edition.
    for folder in ('images', 'reanim'):
        if (game_dir / folder).is_dir():
            shutil.copytree(game_dir / folder, extracted / folder, dirs_exist_ok=True)
    textures = [str(extracted / name) for name in ('reanim', 'seanim', 'images')
                if (extracted / name).is_dir()]
    actors = ('PeaShooterSingle', 'SunFlower', 'Wallnut', 'Zombie', 'Sun', 'LawnMower')
    for actor in actors:
        convert(str(extracted / 'compiled' / 'reanim' / f'{actor}.reanim.compiled'),
                textures, str(ROOT / 'assets' / 'actors' / f'{actor.lower()}.tscn'),
                'res://assets/actors/textures')
    art = ROOT / 'assets' / 'images'
    art.mkdir(parents=True, exist_ok=True)
    for name in ('background1.jpg', 'SeedBank.png', 'SeedPacket_Larger.png',
                 'ProjectilePea.png', 'Shovel.png', 'ShovelBank.png'):
        shutil.copy2(extracted / 'images' / name, art / name)
    sounds = ROOT / 'assets' / 'sounds'
    sounds.mkdir(parents=True, exist_ok=True)
    for name in ('plant.ogg', 'splat.ogg', 'points.ogg', 'groan.ogg', 'chomp.ogg'):
        source = extracted / 'sounds' / name
        if source.exists():
            shutil.copy2(source, sounds / name)
    prepare_v1(extracted)
    prepare_motion(extracted)
    print('Minimal game assets ready.')


def prepare_v1(extracted: Path):
    """Select original UI, damage-stage and particle textures; never download art."""
    groups = {
        'images': ('seeds.png', 'plantshadow.png', 'FlagMeter.png',
                   'FlagMeterLevelProgress.png', 'FlagMeterParts.png',
                   'button_left.png', 'button_middle.png', 'button_right.png',
                   'button_down_left.png', 'button_down_middle.png', 'button_down_right.png'),
        'reanim': ('Wallnut_cracked1.png', 'Wallnut_cracked2.png',
                   'Zombie_outerarm_upper2.png', 'Zombie_cone1.png',
                   'Zombie_cone2.png', 'Zombie_cone3.png'),
        'particles': ('ZombieArm.png', 'ZombieHead.png', 'Pea_particles.png', 'pea_splats.png'),
        'sounds': ('throw.ogg', 'throw2.ogg', 'lawnmower.ogg', 'limbs_pop.ogg', 'seedlift.ogg'),
    }
    for folder, names in groups.items():
        destination = ROOT / 'assets' / ('sounds' if folder == 'sounds' else 'images')
        destination.mkdir(parents=True, exist_ok=True)
        for name in names:
            shutil.copy2(extracted / folder / name, destination / name)
    # Assemble the original nine dialog pieces as one nine-patch texture.
    from PIL import Image
    panel = Image.new('RGBA', (320, 265))
    for row, prefix, y in ((0, 'top', 0), (1, 'center', 97), (2, 'bottom', 151)):
        for suffix, x in (('left', 0), ('middle', 107), ('right', 200)):
            tile = Image.open(extracted / 'images' / f'dialog_{prefix}{suffix}.png').convert('RGBA')
            panel.alpha_composite(tile, (x, y))
    panel.save(ROOT / 'assets' / 'images' / 'dialog.png')


def prepare_motion(extracted: Path):
    """Preserve non-rendering tracks that drive gameplay in the original engine."""
    import json
    fps, tracks = parse_reanim(str(extracted / 'compiled/reanim/Zombie.reanim.compiled'))
    labels, _ = split_labels(tracks)
    ground = next(track for track in tracks if track.name == '_ground')
    samples, x = [], 0.0
    for pose in ground.transforms:
        if pose[0] is not None:
            x = pose[0]
        samples.append(x)
    clips = {}
    for name in ('walk', 'walk2'):
        start, end = labels['anim_' + name]
        values = samples[start:end]
        clips[name] = {'fps': fps, 'length': (end-start)/fps,
                       'x': [value-values[0] for value in values]}
    (ROOT / 'assets/actors/zombie_motion.json').write_text(
        json.dumps(clips, indent=2), encoding='utf-8')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    import os
    os.chdir(ROOT)  # Converter writes res:// paths relative to the current directory.
    prepare(Path(sys.argv[1]).resolve())
