#!/usr/bin/env python3
"""Fail closed when a release violates VietLunar's offline sandbox policy."""

import plistlib
import sys


def main():
    try:
        with open(sys.argv[1], 'rb') as source:
            entitlements = plistlib.load(source)
        if entitlements.get('com.apple.security.app-sandbox') is not True:
            raise ValueError('com.apple.security.app-sandbox must be true')
        for key in ('com.apple.security.get-task-allow', 'get-task-allow',
                    'com.apple.security.network.client', 'com.apple.security.network.server'):
            if key in entitlements and entitlements[key] is not False:
                raise ValueError(f'{key} must be absent or false')
    except (IndexError, OSError, ValueError, AttributeError, plistlib.InvalidFileException) as error:
        print(f'Invalid release entitlements: {error}', file=sys.stderr)
        return 1
    print('Release entitlements verified')
    return 0


if __name__ == '__main__':
    sys.exit(main())
