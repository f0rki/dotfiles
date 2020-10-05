#!/usr/bin/env python

import argparse
import json
import math
import os
import re
import sys
from datetime import datetime, timedelta

# print(sys.argv)

icons = {
    "overdue": "⚠️",
    "due_today": "‼️",
    "due_tmr": "❗",
    "due_future": "📝",
}

# waybar_json_schema = {
#     "text": "",
#     "alt": "",
#     "tooltip": "",
#     "class": "",
#     "percentage": ""
# }

if __name__ == "__main__":
    argv = sys.argv[2:]
    parser = argparse.ArgumentParser()
    # parser.add_argument("todo_file", type=argparse.FileType('r'))
    parser.add_argument("--future-days", default=7, type=int)
    args = parser.parse_args(argv)
    future_days = args.future_days

    todo_file = open(os.getenv("TODO_FILE"), "r")

    overdue = list()
    due_today = list()
    due_tmr = list()
    due_future = list()
    tasks_with_date = list()
    tasks_without_date = list()

    # Open todo.txt file
    content = todo_file.readlines()
    date = datetime.today()

    key = os.getenv("TODO_TXT_DUE_KEY", "due")

    for i, task in enumerate(content):
        task = task.strip()
        match = re.findall(key + r":(\d{4}-\d{2}-\d{2})", task)

        if match:
            date = datetime.strptime(match[0], "%Y-%m-%d").date()
            tasks_with_date.append((i, task, date))
        else:
            tasks_without_date.append((i, task))

    # Sort tasks with a due date: regex by date, then priority
    sorted_tasks = sorted(tasks_with_date, key=lambda tup: (tup[2], tup[1]))
    zero_pad = int(math.log10(len(content))) + 1

    # Append to relevant lists for output

    for task in sorted_tasks:
        # Add matching tasks to list with line number

        if task[2] < datetime.today().date():
            overdue.append(str(task[0] + 1).zfill(zero_pad) + " " + task[1])
        elif task[2] == datetime.today().date():
            due_today.append(str(task[0] + 1).zfill(zero_pad) + " " + task[1])
        elif task[2] == datetime.today().date() + timedelta(days=1):
            due_tmr.append(str(task[0] + 1).zfill(zero_pad) + " " + task[1])
        elif task[2] < datetime.today().date() + timedelta(days=future_days +
                                                           1):
            due_future.append(str(task[0] + 1).zfill(zero_pad) + " " + task[1])

    # undated tasks
    sorted_undated_tasks = sorted(map(lambda x: x[1], tasks_without_date))

    text = []

    if overdue:
        text.append(f"{icons['overdue']}{len(overdue)}")

    if due_today:
        text.append(f"{icons['due_today']}{len(due_today)}")

    if due_tmr:
        text.append(f"{icons['due_tmr']}{len(due_tmr)}")

    if due_future:
        text.append(f"{icons['due_future']}{len(due_future)}")

    categories = []

    for category, color in ((overdue, "red"), 
                            (due_today, "red"), 
                            (due_tmr, "yellow"), 
                            (due_future, ""),
                            (sorted_undated_tasks, "")):
        # print(category, file=sys.stderr)

        if category:
            entries = []
            for entry in category:
                if '(A)' in entry:
                    entries.append(f"<span foreground=\"red\">{entry}</span>")
                if '(B)' in entry:
                    # blue-ish
                    entries.append(f"<span foreground=\"#00bfff\">{entry}</span>")
                if '(C)' in entry:
                    # yellow/green-ish
                    entries.append(f"<span foreground=\"#ace600\">{entry}</span>")

            cat_text = "\n".join(entries)

            cat_text += f"\n<b>{'=' * 80}</b>\n"

            categories.append(cat_text)

    tooltip_text = "".join(categories)

    if not text:
        text = ["⭕"]

    return_json = {"text": " ".join(text), "tooltip": tooltip_text}

    print(json.dumps(return_json))
