#!/usr/bin/env python3
import argparse
import logging
import sys
import signal
import gi
import json

gi.require_version('Playerctl', '2.0')
from gi.repository import Playerctl, GLib

logger = logging.getLogger(__name__)

MAX_WIDTH = 32
ELLIPSIS = u"\u2026"
STOPPED = '⏹️ '


def write_default_output():
    sys.stdout.write(
        json.dumps({
            "text": STOPPED,
            "tooltip": "<i>No Player connected</i>"
        }) + '\n')
    sys.stdout.flush()


def write_output(text, player, text_long=None):
    logger.info('Writing output')

    if len(text) > MAX_WIDTH:
        text = text[:MAX_WIDTH] + " " + ELLIPSIS

    output = {
        'text': text,
        'class': 'custom-' + player.props.player_name,
        'alt': player.props.player_name
    }

    if text_long:
        output['tooltip'] = text_long

    sys.stdout.write(json.dumps(output) + '\n')
    sys.stdout.flush()


def on_play_pause(player, status, manager):
    logger.info('Received new playback status')
    on_metadata(player, player.props.metadata, manager)


def on_metadata(player, metadata, manager):
    logger.info('Received new metadata')
    track_info = ''

    if player.props.player_name == 'spotify' and \
            'mpris:trackid' in metadata.keys() and \
            ':ad:' in player.props.metadata['mpris:trackid']:
        track_info = 'AD PLAYING'
    elif player.get_artist() and player.get_title():
        track_info = '{artist} - {title}'.format(artist=player.get_artist(),
                                                 title=player.get_title())
    elif player.get_title():
        track_info = player.get_title()
    else:
        track_info = "???"

    if player.props.status != 'Playing' and track_info:
        track_info = ' ' + track_info
    elif player.props.status == 'Playing' and track_info:
        track_info = '🎜 ' + track_info
    else:
        track_info = STOPPED
        # track_info = ''

    meta = [f"<b>{player.props.status}</b>\n"]
    meta_fields = (
        ("Title", player.get_title()),
        ("Artist", player.get_artist()),
        ("Album", player.get_album()),
    )

    for k, v in meta_fields:
        if v:
            meta.append(f"<i>{k}:</i> {v}")
    text_long = "\n".join(meta)
    write_output(track_info, player, text_long)


def on_player_appeared(manager, player, selected_player=None):
    if player is not None and (selected_player is None
                               or player.name == selected_player):
        init_player(manager, player)
    else:
        logger.debug(
            "New player appeared, but it's not the selected player, skipping")


def on_player_vanished(manager, player):
    logger.info('Player has vanished')
    if not manager.props.player_names:
        write_default_output()


def init_player(manager, name):
    logger.debug('Initialize player: {player}'.format(player=name.name))
    player = Playerctl.Player.new_from_name(name)
    player.connect('playback-status::playing', on_play_pause, manager)
    player.connect('playback-status::paused', on_play_pause, manager)
    player.connect('metadata', on_metadata, manager)
    manager.manage_player(player)
    on_metadata(player, player.props.metadata, manager)


def signal_handler(sig, frame):
    logger.debug('Received signal to stop, exiting')
    sys.stdout.write('\n')
    sys.stdout.flush()
    # loop.quit()
    sys.exit(0)


def parse_arguments():
    parser = argparse.ArgumentParser()

    # Increase verbosity with every occurence of -v
    parser.add_argument('-v', '--verbose', action='count', default=0)

    # Define for which player we're listening
    parser.add_argument('--player')

    return parser.parse_args()


def main():
    arguments = parse_arguments()

    # Initialize logging
    logging.basicConfig(stream=sys.stderr,
                        level=logging.DEBUG,
                        format='%(name)s %(levelname)s %(message)s')

    # Logging is set by default to WARN and higher.
    # With every occurrence of -v it's lowered by one
    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    # Log the sent command line arguments
    logger.debug('Arguments received {}'.format(vars(arguments)))

    manager = Playerctl.PlayerManager()
    loop = GLib.MainLoop()

    manager.connect('name-appeared',
                    lambda *args: on_player_appeared(*args, arguments.player))
    manager.connect('player-vanished', on_player_vanished)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # sane initial value for waybar to consume.
    write_default_output()

    for player in manager.props.player_names:
        if arguments.player is not None and arguments.player != player.name:
            logger.debug(
                '{player} is not the filtered player, skipping it'.format(
                    player=player.name))

            continue

        init_player(manager, player)

    loop.run()


if __name__ == '__main__':
    main()
