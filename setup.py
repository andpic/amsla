#!/usr/bin/python3

#  @copyright Copyright 2019-2020 Andrea Picciau
#
#  @license Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import os
import sys
import subprocess
import argparse
import shutil


def _this_scripts_dir():
    ''' The path to this script's dir. '''
    this_path = os.path.dirname(os.path.realpath(__file__))
    return this_path


def _default_build_dir():
    ''' Get the path of the default build dir. '''
    build_dir = os.path.join(_this_scripts_dir(), 'build')
    build_dir_abs = os.path.abspath(build_dir)
    return build_dir_abs


def _default_source_dir():
    ''' Get the path of the default source dir. '''
    test_dir = os.path.join(_default_build_dir(), 'source', 'cpp')
    return test_dir


def _default_test_dir():
    ''' Get the path of the default test dir. '''
    test_dir = os.path.join(_default_build_dir(), 'test', 'cpp')
    return test_dir


def _create_new_build_dir():
    ''' Remove previously existing build dir and create a new one '''
    build_dir = _default_build_dir()
    # Delete directory if it exists
    if os.path.exists(build_dir):
        print("Removing directory: " + build_dir)
        shutil.rmtree(build_dir, ignore_errors=True)
    print("Creating directory: " + build_dir)
    os.makedirs(build_dir)
    return build_dir


def _parse_args():
    ''' Parse the input arguments '''
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--debug', action='store_true',
                        help='create a debug build.')
    parser.add_argument('-c', '--code-coverage', action='store_true',
                        help='create a code coverage build.')
    parser.add_argument('-n', '--no-tests',
                        action='store_true', help='do not build tests.')
    parser.add_argument('-t', '--run-tests',
                        action='store_true', help='execute the tests.')
    parser.add_argument('-m', '--module', action='store',
                        help='run the tests for the specific module.')

    args = parser.parse_args()

    assert not(
        args.no_tests and args.run_tests), "Arguments --no-tests and --run-tests are mutually exclusive."
    from sys import platform
    assert not(
        args.code_coverage and platform != "linux"), "Code coverage is only available on linux."

    return args


class Tasks:
    """ Tasks to be executed for the build """
    prebuild_task = 'cmake .. -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON'
    build_task = 'cmake --build .'
    build_path = _default_source_dir()
    build_test_task = 'cmake --build .'
    build_test_path = _default_test_dir()
    test_task = 'ctest --verbose -T Test'
    test_path = _default_test_dir()
    post_test_task = ''
    post_test_path = _default_build_dir()


def _configure_build_type(tasks, is_debug):
    ''' Enable or disable debug build '''
    if is_debug:
        config = 'Debug'
    else:
        config = 'Release'
    tasks.prebuild_task = tasks.prebuild_task + " -DCMAKE_BUILD_TYPE=" + config
    tasks.build_task = tasks.build_task + " --config " + config
    tasks.build_test_task = tasks.build_test_task + " --config " + config
    tasks.test_task = tasks.test_task + " -C " + config
    return tasks


def _is_chrome_available():
    ''' Returns true if chrome is installed '''
    try:
        subprocess.check_call(['google-chrome', '--version'])
        is_available = True
    except FileNotFoundError as _:
        is_available = False
    return is_available


def _configure_code_coverage(task):
    ''' Enable code coverage '''
    task.prebuild_task = task.prebuild_task + " -DCODE_COVERAGE=1"
    coverage = 'code_coverage.info'
    report_dir = 'code_coverage_report'
    task.post_test_task = [
        "lcov --directory . --capture --output-file " + coverage,
        "lcov --remove " + coverage + " --output-file " + coverage + ' /usr/*',
        "lcov --remove " + coverage + " --output-file " + coverage + ' 7/*',
        "lcov --remove " + coverage + " --output-file " + coverage + ' */derived*',
        "lcov --list " + coverage,
        "genhtml " + coverage + " --output-directory " + report_dir]
    if _is_chrome_available():
        task.post_test_task.append(
            "google-chrome " + os.path.join(report_dir, "index.html"))
    return task


def _select_module(task, module=None):
    ''' Select a specific module to build and test '''
    if not module:
        module = ''
    task.build_path = os.path.join(_default_source_dir(), module)
    task.build_test_path = os.path.join(_default_test_dir(), module)
    task.test_path = os.path.join(_default_test_dir(), module)
    return task


def _disable_test_runs(task):
    ''' Do not execute tests '''
    task.test_task = ''
    task.post_test_task = ''
    return task


def _disable_tests(task):
    ''' Do not build test '''
    task.build_test_task = ''
    task = _disable_test_runs(task)
    return task


def _configure_amsla_build(is_debug, is_coverage, is_no_tests, is_running_tests, module):
    ''' Configure the build for AMSLA '''
    _create_new_build_dir()

    tasks = Tasks()
    tasks = _configure_build_type(tasks, is_debug)

    if is_coverage:
        tasks = _configure_code_coverage(tasks)

    if module:
        tasks = _select_module(tasks, module)

    if is_no_tests:
        tasks = _disable_tests(tasks)
    elif not is_running_tests:
        tasks = _disable_test_runs(tasks)

    return tasks


def _change_dir(dir_path):
    ''' Change directory '''
    if dir_path:
        print("Changing directory to: " + dir_path)
        os.chdir(dir_path)


def _execute_task(command):
    ''' Execute a given command in the shell '''
    if command:
        print("Executing build task: " + command)
        try:
            subprocess.check_call(command.split())
        except subprocess.CalledProcessError as _:
            sys.exit(os.EX_SOFTWARE)


def _execute_amsla_build(tasks):
    ''' Execute tasks from the build '''
    _change_dir(_default_build_dir())
    _execute_task(tasks.prebuild_task)

    _change_dir(tasks.build_path)
    _execute_task(tasks.build_task)

    _change_dir(tasks.build_test_path)
    _execute_task(tasks.build_test_task)

    _change_dir(tasks.test_path)
    _execute_task(tasks.test_task)

    _change_dir(tasks.post_test_path)
    for current_task in tasks.post_test_task:
        _execute_task(current_task)

    sys.exit(os.EX_OK)


if __name__ == '__main__':
    ''' Helper for AMSLA: compile and run tests. '''
    args = _parse_args()

    tasks = _configure_amsla_build(args.debug,
                                   args.code_coverage,
                                   args.no_tests,
                                   args.run_tests,
                                   args.module)
    _execute_amsla_build(tasks)
