"""Create JSON file with all the constellation names"""
import pathlib
import os
import typer
import json
def main(constellation_path: pathlib.Path, output_path: pathlib.Path):
    stars = []
    for (root,dirs,files) in os.walk(constellation_path, topdown=True):
        if len(dirs) == 0:
            if "match.json" in files:
                with open(pathlib.Path(root, "match.json"),"r") as f:
                    stars.append(json.load(f))
            else:
                with open(pathlib.Path(root, "info.json"),"r") as f:
                    stars.append(json.load(f))
    stars.sort(key = lambda x: x['constellation'])
    with open(output_path, 'w') as f:
        json.dump(stars, f)

if __name__ == '__main__':
    typer.run(main)