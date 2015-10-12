#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Helper for updating snapshot of Observatory dependencies"""

import argparse
import errno
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import urllib
import urlparse

SELF_PACKAGE_NAME = 'observatory'
SCRIPT_DIR = os.path.dirname(sys.argv[0])

def check_for_pubspec_yaml(directory):
  return os.path.exists(os.path.join(directory, 'pubspec.yaml'))

def run_pub_get(directory):
  os.chdir(directory)
  print('Running pub get in %s' % directory)
  subprocess.check_output(['pub', 'get'])

def get_package_name(package_config):
  return package_config.split(':', 1)[0]

def get_package_path(package_config):
  return os.path.abspath(
      os.path.join(
          urlparse.urlparse(
              urllib.unquote(
                  package_config.split(':', 1)[1])).path.strip(),
          '..'))

def snapshot_package(src, dst):
  shutil.copytree(src, dst)

def update_packages(src, dst):
  print('Deleting %s' % dst)
  try:
    shutil.rmtree(dst)
  except OSError as e:
    if e.errno != errno.ENOENT:
      raise e
    pass
  with open(src) as f:
    packages = f.read().splitlines()
  print('Snapshotting packages into %s' % dst)
  for package_config in packages:
    if package_config.startswith('#'):
      # Skip comments.
      continue
    package_name = get_package_name(package_config)
    if package_name == SELF_PACKAGE_NAME:
      # Skip self.
      continue
    package_dir = get_package_path(package_config)
    print('Snapshotting package %s' % package_name)
    snapshot_package(package_dir, os.path.join(dst, package_name))


def rewrite_pubspec_yaml(packages_src, yaml_src, yaml_dst):
  with open(yaml_src) as f:
    yaml = f.read().splitlines()
  yaml = [line for line in yaml if line.strip()]
  yaml.insert(0, '# Generated file DO NOT EDIT')
  yaml.append('dependency_overrides:')
  with open(packages_src) as f:
    packages = f.read().splitlines()
  for package_config in packages:
    if package_config.startswith('#'):
      # Skip comments.
      continue
    package_name = get_package_name(package_config)
    if package_name == SELF_PACKAGE_NAME:
      # Skip self.
      continue
    yaml.append('  %s:' % package_name)
    yaml.append(
        '    path: ../../third_party/observatory_pub_packages/packages/%s'
        % package_name)
  yaml.append('')
  print('!!! Update Observatory pubspec.yaml in sdk source tree')
  with open(yaml_dst, 'w') as f:
    f.write('\n'.join(yaml))

def main():
  parser = argparse.ArgumentParser(
      description='Updating snapshot of Observatory dependencies')
  parser.add_argument(
      '--dart-sdk-src',
      action='store',
      metavar='dart_sdk_src',
      help='Path to dart/sdk',
      default='~/workspace/dart/sdk')
  args = parser.parse_args()
  args.dart_sdk_src = os.path.abspath(os.path.expanduser(args.dart_sdk_src))
  observatory_dir = os.path.join(args.dart_sdk_src, 'runtime', 'observatory')

  if not check_for_pubspec_yaml(SCRIPT_DIR):
    print('Error could not find pubspec.yaml next to roll.py')
    return 1

  if not check_for_pubspec_yaml(observatory_dir):
    print('Error could not find Observatory source.')
    return 1

  yaml_src = os.path.abspath(os.path.join(SCRIPT_DIR, 'pubspec.yaml'))
  yaml_dst = os.path.abspath(os.path.join(observatory_dir, 'pubspec.yaml'))

  packages_dst = os.path.abspath(os.path.join(SCRIPT_DIR, 'packages'))

  temp_dir = tempfile.mkdtemp();
  try:
    shutil.copyfile(os.path.join(SCRIPT_DIR, 'pubspec.yaml'),
                    os.path.join(temp_dir, 'pubspec.yaml'))
    packages_src = os.path.join(temp_dir, '.packages')
    run_pub_get(temp_dir)
    update_packages(packages_src, packages_dst)
    rewrite_pubspec_yaml(packages_src, yaml_src, yaml_dst)
  finally:
    shutil.rmtree(temp_dir)

if __name__ == '__main__':
  sys.exit(main());
