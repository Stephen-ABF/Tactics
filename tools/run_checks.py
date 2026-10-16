#!/usr/bin/env python3
"""Run the actual Godot suites with isolated player data; fail on script errors."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import sys

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--skip-balance', action='store_true')
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    stages = [['--editor', '--import', '--quit']]
    suites = ['test_rules.gd', 'test_gear.gd', 'test_flow.gd']
    if not args.skip_balance:
        suites.append('balance_probe.gd')
    suites.append('test_expedition.gd')
    stages += [['--script', 'res://tests/' + name] for name in suites]
    with tempfile.TemporaryDirectory(prefix='thornwake-qa-') as temp:
        env = os.environ.copy()
        env.update(XDG_DATA_HOME=temp, APPDATA=temp)
        for stage in stages:
            command = [args.godot, '--headless', '--path', str(project)] + stage
            result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=300)
            print(result.stdout, end='')
            if result.returncode or 'SCRIPT ERROR:' in result.stdout or '\nERROR:' in result.stdout:
                return result.returncode or 1
    print('ALL GODOT CHECKS PASSED')
    return 0

if __name__ == '__main__':
    sys.exit(main())
