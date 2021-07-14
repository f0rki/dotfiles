#!/usr/bin/env python

# Originally taken from Reddit user crunchyrawr (https://www.reddit.com/user/crunchyrawr/)
# posted in the swaywm subreddit (https://www.reddit.com/r/swaywm/comments/hjyy8e/tofi_launcher_alacritty_fzf_python_script/)
# with a bunch of modifications :)

import re
import os
import sys
import itertools
import json
import pathlib
import datetime
import subprocess as sp

from enum import Enum

import i3ipc

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio

ipc = i3ipc.Connection()

HISTORY_PATH = (pathlib.Path("~") / ".cache" / "tofi" /
                "history.json").expanduser()

SHELLS = {
    "fish":
    (["fish", "-c",
      'complete -C "" | grep -v Directory | grep -v \'\\[\''], ["fish", "-c"]),
    "bash": (["bash", "-c", "compgen -c"], ["bash", "c"]),
    "sh": (["sh", "-c", "ls `echo $PATH | tr : ' '`"], ["sh", "-c"])
}

_HISTORY = None


class Markers(Enum):
    APP = "launch"
    WINDOW = "window"
    SHELL = "shell"
    TERMINAL = "term"
    FILES = "files"


# Apps (via gio)


def create_app_search_result(app):
    return '{}: {}: {}'.format(
        Markers.APP.value, app.get_name(), app.get_description(
        )) if app.get_description() != None else "{}: {}".format(
            Markers.APP.value, app.get_name())


def run_app_executable(search_term):
    for binary in map(
            lambda app: app.get_executable() if app.get_executable() !=
            '/usr/bin/flatpak' else app.get_commandline(),
            filter(
                lambda app: create_app_search_result(app).strip() ==
                search_term, Gio.AppInfo.get_all())):
        ipc.command('exec {}'.format(binary))


def list_apps():
    return map(create_app_search_result,
               filter(lambda app: app.should_show(), Gio.AppInfo.get_all()))


# Window Focus


def create_window_search_result(win):
    return "{}: {}".format(str(Markers.WINDOW.value), win.name)


def focus_window(search_term):
    # Should only be one, map doesn't work when used in "launcher" window
    for window in filter(
            lambda item: create_window_search_result(item) == search_term,
            ipc.get_tree()):
        window.command('focus')


def list_windows():
    return map(
        create_window_search_result,
        filter(
            lambda item: item.type == "con" and item.app_id != "tofi" and item.
            name != None, ipc.get_tree()))


# Shell


def create_shell_search_result(x):
    x = re.split("\s+", x, maxsplit=1)
    if len(x) > 1:
        exe, desc = x[0], x[1]
        return "{}: {} # {}".format(str(Markers.SHELL.value), exe, desc)
    else:
        return "{}: {}".format(Markers.SHELL.value, x[0])


def list_shell():
    shell = os.path.basename(os.getenv("SHELL"))
    if shell not in SHELLS:
        shell = "sh"
    l = list(
        map(create_shell_search_result,
            sp.check_output(SHELLS[shell][0], text=True).splitlines()))
    print("using shell:", l, file=sys.stderr)
    return l


def run_shell(cmd):
    if "#" in cmd:
        save_to_history(Markers.SHELL, cmd.split("#")[0].strip())
    else:
        save_to_history(Markers.SHELL, cmd.strip())
    shell = os.path.basename(os.getenv("SHELL"))
    cmd = " ".join(SHELLS[shell][1] + ["\"{}\"".format(cmd)])
    ipc.command('exec {}'.format(cmd))


# History:

#def history_lookup(line, history):


def key_by_history(a):
    global _HISTORY
    if _HISTORY is None:
        try:
            with open(HISTORY_PATH, "r") as f:
                _HISTORY = json.load(f)
        except Exception:
            _HISTORY = {}

    marker_str, value = map(lambda s: s.strip(), a.split(":", maxsplit=1))
    marker = Markers(marker_str)
    if marker.value not in _HISTORY:
        return (datetime.datetime(1900, 1, 1), 0, value)

    if marker == Markers.SHELL:
        value = value.split("#")[0].strip()

    if value not in _HISTORY[marker.value]:
        count = 0
        date = "1900-01-01T00:00:00.000000"
    else:
        count, date = _HISTORY[marker.value][value]

    date = datetime.datetime.fromisoformat(date)

    return (date, count, value)


def dt_now_str():
    return datetime.datetime.now().isoformat()


def save_to_history(marker, value):
    os.makedirs(HISTORY_PATH.parent, exist_ok=True)
    history = {}
    if os.path.exists(HISTORY_PATH):
        with open(HISTORY_PATH, "r+") as f:
            history = json.load(f)

    if marker.value not in history:
        history[marker.value] = {}
    if value not in history[marker.value]:
        history[marker.value][value] = [1, dt_now_str()]
    else:
        history[marker.value][value][0] += 1
        history[marker.value][value][1] = dt_now_str()

    with open(HISTORY_PATH, "w") as f:
        json.dump(history, f)


# TODO: launch terminal / filemanager in directories of zoxide?

if __name__ == "__main__":
    try:
        if not sys.stdin.isatty():
            for line in sys.stdin:
                marker_str, value = map(lambda s: s.strip(),
                                        line.split(":", maxsplit=1))
                marker = Markers(marker_str)
                if marker == Markers.WINDOW:
                    focus_window(line.strip())
                    save_to_history(marker, value)
                elif marker == Markers.APP:
                    run_app_executable(line.strip())
                    save_to_history(marker, value)
                elif marker == Markers.SHELL:
                    run_shell(value.strip())
                else:
                    run_shell(line.strip())
        else:
            print(*sorted(set(
                itertools.chain(
                    list_apps(),
                    list_shell(),
                    list_windows(),
                )),
                          key=key_by_history,
                          reverse=True),
                  sep="\n")
    except Exception as e:
        print("Encountered Error:", file=sys.stderr)
        print(sys.exc_info(), file=sys.stderr)
        print("", file=sys.stderr)
        print("Exit?", file=sys.stderr)
        input()
