""" Match constellations to shot-maps. """
import enum
import itertools
import sys
import json
import pathlib

import pandas as pd
import numpy as np
import tqdm
import typer
from scipy import optimize as op, stats

import geometry


# Matching functions

def find_best_transformation(shots, stars, similarity):
    """
    Find the best set of transformations to match a set of stars
    with a set of shots.
    """
    result = op.minimize(
        lambda x: evaluate_match(shots, stars, *x, similarity=similarity),
        x0=[0, 0, 0, 0],
        bounds=[(-100, 100), (-100, 100), (-np.pi, np.pi), (-200, 200)]
    )
    return result


def evaluate_match(coords1, coords2, angle, dx, dy, log_scale, similarity):
    coords2_transformed = geometry.apply_transformation(
        coords2, angle, dx, dy, log_scale)
    return similarity(coords1, coords2_transformed) + penalise_tiny_transformations(coords2_transformed)


def penalise_tiny_transformations(coords):
    # Very basic, non-optimised penalty function
    # Results generally run fine without it, but a few
    # constellations get nicer matches with it
    x_range = abs(coords[0].max() - coords[0].min())
    y_range = abs(coords[0].max() - coords[0].min())
    average_range = x_range + y_range / 2
    return np.exp(-5*average_range + 2)


# Similarity scores

# Create a registry that maps names:functions for CLI
SIMILARITY_FUNCTIONS = {}


def register_similarity(name):
    def decorator(f):
        SIMILARITY_FUNCTIONS[name] = f
        return f
    return decorator


@register_similarity('euclidean')
def euclidean_similarity(coords1, coords2):
    """
    Calculate the average squared distance between two sets of 2D coordinates.

    Each coordinate will be matched with a coordinate from the other set such that
    the overall mean distance is minimised. This is a case of the linear sum assignment
    problem.
    """

    # Construct cost matrix for linear sum assignment
    n_coords = coords1.shape[1]
    cost_matrix = np.zeros([n_coords, n_coords])
    for i1, i2 in itertools.product(range(n_coords), repeat=2):
        cost_matrix[i1, i2] = geometry.euclidean_distance(
            coords1[:, i1], coords2[:, i2])**2

    # Perform linear sum assignment and get mean squared distance
    sol_rows, sol_cols = op.linear_sum_assignment(cost_matrix)
    mean_dist = cost_matrix[sol_rows, sol_cols].mean()
    return mean_dist


@register_similarity('gaussian')
def gaussian_similarity(coords1, coords2):
    # Create a set of gaussians for each point in coords1 and find the total density
    # of all of those distributions for each point in coords2
    sigma = 0.1
    cov = sigma*np.identity(2)
    total_activation = 0
    n_coords = coords1.shape[1]
    for i1 in range(n_coords):
        # NOTE: the nested loop is ugly BUT it is far more performant than (e.g.)
        # itertools.product, because instantiating the scipy distribution
        # is very slow. Creating a frozen distribution like this, and using that for
        # each pdf is approx. 3-4x faster
        distribution = stats.multivariate_normal(mean=coords1[:, i1], cov=cov)
        for i2 in range(n_coords):
            total_activation += distribution.pdf(coords2[:, i2])
    return -total_activation


# Create an enum for the sake of the Typer CLI
# Using an enum (with string values) as the argument type allows Typer to infer
# what the valid inputs are for the similarity argument
# NOTE: This registry + enum nonsense is slightly cursed. We could do this in a
# simpler way at the cost of a minor bit of repetition, which may be preferable...
Similarity = enum.Enum(
    'Similarity', {k: k for k in SIMILARITY_FUNCTIONS.keys()})
Similarity.func = lambda self, c1, c2: SIMILARITY_FUNCTIONS[self.name](c1, c2)


# Main CLI function

def main(
    shots: typer.FileText,
    constellation_path: pathlib.Path,
    similarity: Similarity = typer.Option('euclidean', show_choices=True)
):
    constellation = constellation_path.name

    # Load the shots and constellation data
    shots = pd.read_csv(shots)
    stars = pd.read_csv(constellation_path/'stars.csv')
    links = pd.read_csv(constellation_path/'links.csv')
    n_stars = len(stars)

    typer.echo('Counting shots for each game...')
    shot_counts = shots[['game_id', 'player_name']].value_counts()
    valid_games = shot_counts.loc[lambda n: n == n_stars]
    typer.echo(
        f'Found {len(valid_games)} possible matches (with {n_stars} shots)...')

    if len(valid_games) == 0: 
        match_metadata = {
        'constellation': constellation,
        'constellation_full_name': stars['name'].iloc[0]
        }
        with open(constellation_path/'info.json', 'w+') as json_file:
            json.dump(match_metadata, json_file)
        return
    # For each valid set of match shots, evaluate the best possible match
    typer.echo(
        f'Matching {constellation} to shot-map, using {similarity.name} similarity...')
    transformations = {}
    for game_id, player_name in tqdm.tqdm(valid_games.index):
        game_shots = shots.loc[lambda df: (df['game_id'] == game_id) & (df['player_name'] == player_name)]

        # Find the best matching score subject to rotation, translation (x and y), and scaling
        # and store the result
        res = find_best_transformation(
            game_shots[['x', 'y']].values.transpose(),
            stars[['x', 'y']].values.transpose(),
            similarity=similarity.func
        )
        transformations[(game_id, player_name)] = res

    typer.echo('Done! Saving output...')

    # Extract the best match and store the result
    game_id, player_name = min(transformations, key=lambda x: transformations[x]['fun'])
    match_result = transformations[(game_id, player_name)]

    # Fetch matched shots
    shots_matched = shots.loc[lambda df: (df['game_id'] == game_id) & (df['player_name'] == player_name)]
    match_metadata = {
        'constellation': constellation,
        'constellation_full_name': stars['name'].iloc[0],
        'game_id': game_id,
        'player_name': player_name,
        'home_name': shots_matched['home_name'].iloc[0],
        'away_name': shots_matched['away_name'].iloc[0],
        'home_final': shots_matched['home_final'].iloc[0],
        'away_final': shots_matched['away_final'].iloc[0],
        'date': shots_matched['date'].iloc[0],
        'distance': match_result['fun'],
        'mean_distance': match_result['fun']/n_stars,
        'transformations': list(match_result['x'])
    }

    if match_metadata['mean_distance'] > 200: 
        match_metadata = {
        'constellation': constellation,
        'constellation_full_name': stars['name'].iloc[0]
        }
        with open(constellation_path/'info.json', 'w+') as json_file:
            json.dump(match_metadata, json_file)
        return

    # Transform stars and links
    stars_transformed = apply_transformation_to_df(stars, match_result['x'])
    links_transformed = apply_transformation_to_df(
        links, match_result['x'],
        pivot=(stars['x'].mean(), stars['y'].mean())
    )

    # Save metadata, matched shots, transformed stars and links
    with open(constellation_path/'match.json', 'w+') as json_file:
        json.dump(match_metadata, json_file)

    shots_matched.to_csv(constellation_path/'shots.csv', index=False)
    stars_transformed.to_csv(
        constellation_path/'stars_transformed.csv', index=False)
    links_transformed.to_csv(
        constellation_path/'links_transformed.csv', index=False)


def parse_similarity(name, default):
    f = SIMILARITY_FUNCTIONS.get(name)
    if f is None:
        typer.echo(f'Unknown similarity "{name}"! Defaulting to "{default}"!')
        f = SIMILARITY_FUNCTIONS[default]
    return f


def apply_transformation_to_df(df, transformations, pivot=None, xcol='x', ycol='y'):
    df = df.copy()
    coords = df[[xcol, ycol]].values.transpose()
    coords_transformed = geometry.apply_transformation(
        coords, *transformations, pivot=pivot)
    df[['x', 'y']] = coords_transformed.transpose()
    return df


if __name__ == '__main__':
    typer.run(main)
