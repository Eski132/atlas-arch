"""No root, vendor archive, or real mounts required."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherTests(unittest.TestCase):
    def test_generated_files_match_sources(self):
        subprocess.run(['python3', str(ROOT / 'tools/sync-installer.py'), '--check'], check=True)

    def test_shell_syntax(self):
        for name in ('install.sh', 'cloudpath-arch', 'cloudpath-arch-ns', 'cloudpath-arch-mount-run', 'PKGBUILD'):
            subprocess.run(['bash', '-n', str(ROOT / name)], check=True)

    def run_payload(self, extra, assertions, status=0):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            def script(name, content):
                path = base / name
                path.write_text('#!/bin/bash\nset -eu\n' + content)
                path.chmod(0o755)
            script('mount', 'exit 0\n')
            # Model the environment reset at the privilege boundary, without
            # invoking privileged operations or changing the test runner UID.
            script('setpriv', 'while [[ $1 != env ]]; do shift; done\nexec /usr/bin/env -i "$@"\n')
            script('Cloudpath-x64', assertions + f'\nexit {status}\n')
            env = {'PATH': f'{base}:/usr/bin:/bin', 'HOME': directory, **extra}
            return subprocess.run(['bash', str(ROOT / 'cloudpath-arch-mount-run'),
                                   str(os.getuid()), str(os.getgid()), directory,
                                   directory, directory], env=env, capture_output=True)

    def test_unset_desktop_defaults_stay_unset(self):
        result = self.run_payload({}, '[[ ! -v XDG_DATA_DIRS && ! -v LC_ALL && ! -v XDG_CONFIG_HOME ]]')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_wayland_session_and_spaces_survive_reset(self):
        result = self.run_payload({'WAYLAND_DISPLAY': 'wayland-1', 'DISPLAY': ':1',
                                   'XDG_CURRENT_DESKTOP': 'Hyprland',
                                   'XDG_DATA_DIRS': '/a path:/usr/share', 'LC_ALL': ''},
                                  '[[ $WAYLAND_DISPLAY == wayland-1 && $DISPLAY == :1 ]]\n'
                                  '[[ $XDG_CURRENT_DESKTOP == Hyprland ]]\n'
                                  '[[ $XDG_DATA_DIRS == "/a path:/usr/share" && -v LC_ALL && -z $LC_ALL ]]')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_vendor_failure_is_preserved(self):
        result = self.run_payload({}, ':', status=134)
        self.assertEqual(result.returncode, 134, result.stderr)


if __name__ == '__main__':
    unittest.main()
