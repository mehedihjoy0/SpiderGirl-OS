#!/usr/bin/env python3
"""
Smalipatcher: A utility tool to apply patches to smali files.

Features:
- Parses .smalipatch files.
- Applies REPLACE, FIND_REPLACE, and PATCH operations.
- Dynamically resolves mismatched smali_classesN directory numbers.
- Detects ambiguous class paths.
"""

import os
import sys
import re
import argparse
from typing import List, Tuple, Optional


class Colors:
    """ANSI color codes."""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

    @staticmethod
    def init():
        if os.name == 'nt':
            try:
                import colorama
                colorama.init()
            except ImportError:
                pass


def log(msg: str, color: str = '', quiet: bool = False):
    if not quiet:
        print(f"{color}{msg}{Colors.RESET if color else ''}")


def log_error(msg: str):
    print(f"{Colors.RED}{msg}{Colors.RESET}")


def parse_quoted_args(text: str) -> List[str]:
    """Parse quoted arguments, supporting escaped characters."""
    args = []
    in_quote = False
    current = []
    i = 0

    while i < len(text):
        c = text[i]

        if c == '"':
            if in_quote:
                args.append(''.join(current))
                current = []
                in_quote = False
            else:
                in_quote = True

        elif in_quote:
            if c == '\\' and i + 1 < len(text):
                current.append(text[i + 1])
                i += 1
            else:
                current.append(c)

        i += 1

    return args


def parse_smalipatch(lines: List[str]) -> List[dict]:
    """Parse a .smalipatch file into patch actions."""
    patches = []
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        if not line or line.startswith('#') or line.startswith('//'):
            i += 1
            continue

        if line.startswith('AUTHOR '):
            author = line[7:].strip()
            log(f"  Author: {author}", Colors.BLUE)
            i += 1
            continue

        if not line.startswith('FILE '):
            i += 1
            continue

        file_path = line[5:].strip()

        patch = {
            'type': 'FILE',
            'file_path': file_path,
            'actions': []
        }

        i += 1

        while i < len(lines):
            line = lines[i].strip()

            if not line or line.startswith('#') or line.startswith('//'):
                i += 1
                continue

            if line == 'END':
                i += 1
                break

            if line.startswith('FILE '):
                break

            if line.startswith('REPLACE '):
                method_sig = line[8:].strip()
                content, i = read_content_block(lines, i + 1)

                patch['actions'].append({
                    'type': 'REPLACE',
                    'method_sig': method_sig,
                    'content': content
                })

            elif line.startswith('FIND_REPLACE '):
                parts = parse_quoted_args(line[13:])

                if len(parts) == 2:
                    patch['actions'].append({
                        'type': 'FIND_REPLACE',
                        'old': parts[0],
                        'new': parts[1]
                    })
                else:
                    log_error(
                        f"Invalid FIND_REPLACE syntax in patch file: {line}"
                    )

                i += 1

            elif line == 'PATCH' or line.startswith('PATCH '):
                rest = line[5:].strip()
                method_sig = rest if rest else None

                content, i = read_content_block(lines, i + 1)

                patch['actions'].append({
                    'type': 'PATCH',
                    'method_sig': method_sig,
                    'content': content
                })

            else:
                i += 1

        if patch['actions']:
            patches.append(patch)

    return patches


def read_content_block(
    lines: List[str],
    start: int
) -> Tuple[List[str], int]:
    """Read a patch content block until the next action or FILE boundary."""
    content = []
    i = start

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if (
            stripped == 'END'
            or stripped.startswith('REPLACE ')
            or stripped == 'PATCH'
            or stripped.startswith('PATCH ')
            or stripped.startswith('FIND_REPLACE ')
            or stripped.startswith('FILE ')
        ):
            break

        content.append(line.rstrip())
        i += 1

    return content, i


def normalize_line(line: str) -> str:
    return line.strip()


def find_method_range(
    lines: List[str],
    method_sig: str
) -> Tuple[int, int]:
    """Find a method declaration and its .end method line."""
    pattern = re.compile(r'^\s*' + re.escape(method_sig))

    for i, line in enumerate(lines):
        if pattern.match(line):
            for j in range(i + 1, len(lines)):
                if lines[j].strip() == '.end method':
                    return i, j

            # Fallback if .end method is missing.
            for j in range(i + 1, len(lines)):
                if lines[j].strip().startswith('.end class'):
                    return i, j - 1

            return i, len(lines) - 1

    return -1, -1


def apply_replace(
    lines: List[str],
    action: dict,
    quiet: bool
) -> Optional[List[str]]:
    """Replace a complete method body."""
    method_sig = action['method_sig']
    start_idx, end_idx = find_method_range(lines, method_sig)

    if start_idx == -1:
        log_error(f"  ✗ Method not found: {method_sig}")
        return None

    new_lines = lines[:start_idx]
    new_lines.append(lines[start_idx])
    new_lines.extend(action['content'])

    has_end_method = any(
        line.strip() == '.end method'
        for line in action['content']
    )

    if not has_end_method:
        new_lines.append('.end method')

    new_lines.extend(lines[end_idx + 1:])

    log(
        f"    ✓ Replaced method at line {start_idx + 1}",
        Colors.GREEN,
        quiet
    )

    return new_lines


def apply_find_replace(
    lines: List[str],
    action: dict,
    quiet: bool
) -> Optional[List[str]]:
    """Replace all occurrences of a string in the file."""
    old_val = action['old']
    new_val = action['new']

    if not old_val:
        log_error("  ✗ FIND_REPLACE cannot use an empty search string")
        return None

    count = 0
    new_lines = []

    for line in lines:
        occurrences = line.count(old_val)

        if occurrences:
            new_lines.append(line.replace(old_val, new_val))
            count += occurrences
        else:
            new_lines.append(line)

    if count == 0:
        log_error(f"  ✗ Pattern not found: {old_val}")
        return None

    log(
        f"    ✓ Replaced {count} occurrence(s)",
        Colors.GREEN,
        quiet
    )

    return new_lines


def apply_patch(
    lines: List[str],
    action: dict,
    quiet: bool
) -> Optional[List[str]]:
    """Apply a context-based patch."""
    content = action['content']
    method_sig = action.get('method_sig')

    context_lines = []
    changes = []

    for line in content:
        if line.startswith('+ '):
            changes.append(('+', line[2:]))

        elif line.startswith('- '):
            changes.append(('-', line[2:]))

        else:
            context_lines.append(normalize_line(line))

    search_start = 0
    search_end = len(lines)

    if method_sig:
        start_idx, end_idx = find_method_range(lines, method_sig)

        if start_idx == -1:
            log_error(f"  ✗ Method not found: {method_sig}")
            return None

        search_start = start_idx
        search_end = end_idx + 1

    if context_lines:
        match_start = -1
        match_end = -1

        for i in range(search_start, search_end):
            line_idx = i
            matched = True

            for ctx in context_lines:
                # Ignore blank lines between context lines.
                while (
                    line_idx < search_end
                    and not normalize_line(lines[line_idx])
                ):
                    line_idx += 1

                if line_idx >= search_end:
                    matched = False
                    break

                if normalize_line(lines[line_idx]) != ctx:
                    matched = False
                    break

                line_idx += 1

            if matched:
                match_start = i
                match_end = line_idx
                break

        if match_start == -1:
            log_error("  ✗ Context not found")

            if context_lines:
                log_error(
                    f"     Looking for: {context_lines[0][:50]}..."
                )

            return None

        # Preserve blank lines and context lines before the first
        # actual removal, and apply additions/removals in order.
        #
        # Context lines describe the matched region. Change lines
        # are applied sequentially to that region.
        matched_region = lines[match_start:match_end]
        result_region = matched_region[:]
        cursor = 0

        for op, text in changes:
            if op == '+':
                result_region.insert(cursor, text)
                cursor += 1

            elif op == '-':
                found = False

                for j in range(cursor, len(result_region)):
                    if normalize_line(result_region[j]) == normalize_line(text):
                        del result_region[j]
                        found = True
                        break

                if not found:
                    log_error(
                        f"  ✗ Removal line not found in matched context: {text}"
                    )
                    return None

        new_lines = (
            lines[:match_start]
            + result_region
            + lines[match_end:]
        )

        log(
            f"     Applied patch at line {match_start + 1}",
            Colors.GREEN,
            quiet
        )

        return new_lines

    # A patch without context adds the requested lines to the file.
    new_lines = lines[:]

    for op, text in changes:
        if op == '+':
            new_lines.append(text)

    log("     Applied patch", Colors.GREEN, quiet)
    return new_lines


def resolve_file_path(
    work_dir: str,
    file_path: str
) -> Optional[str]:
    """
    Resolve smali file paths, supporting:
      FILE smali/path/Class.smali
      FILE smali_classes2/path/Class.smali
      FILE */path/Class.smali

    Wildcard paths search all smali and smali_classesN directories.
    Exact paths are preferred when explicitly specified.
    Ambiguous matches are rejected.
    """
    portable_path = file_path.replace('\\', '/').strip()
    portable_path = re.sub(r'^(?:\./)+', '', portable_path)

    # Handle FILE */package/Class.smali
    wildcard_match = re.fullmatch(r'\*/(.+)', portable_path)

    if wildcard_match:
        relative_path = wildcard_match.group(1)
        search_prefix = ''
        wildcard = True

    else:
        # Prefer an exact path when explicitly specified.
        normalized_path = os.path.normpath(file_path)
        direct_path = os.path.join(work_dir, normalized_path)

        if os.path.isfile(direct_path):
            return normalized_path

        # Handle explicit smali directory paths.
        match = re.fullmatch(
            r'(?:(.*)/)?(smali(?:_classes\d+)?)/(.+)',
            portable_path
        )

        if not match:
            return None

        search_prefix, _, relative_path = match.groups()
        search_prefix = search_prefix or ''
        wildcard = False

    # Search within the appropriate root.
    search_root = os.path.join(work_dir, search_prefix)

    if not os.path.isdir(search_root):
        return None

    candidates = []

    try:
        for current_root, dirs, _ in os.walk(search_root):
            dirs.sort()

            # Only inspect directories named smali or smali_classesN.
            if not re.fullmatch(
                r'smali(?:_classes\d+)?',
                os.path.basename(current_root)
            ):
                continue

            candidate = os.path.join(
                current_root,
                relative_path.replace('/', os.sep)
            )

            if os.path.isfile(candidate):
                candidates.append(
                    os.path.relpath(candidate, work_dir)
                )

    except OSError as e:
        log_error(f"   Failed to search smali directories: {e}")
        return None

    candidates = sorted(set(candidates))

    if not candidates:
        return None

    if len(candidates) > 1:
        log_error(f"   Ambiguous smali path: {file_path}")

        for candidate in candidates:
            log_error(f"     Candidate: {candidate}")

        log_error(
            "   Multiple matching classes found. "
            "Specify an explicit smali directory."
        )
        return None

    return candidates[0]


def apply_patch_to_file(
    work_dir: str,
    patch: dict,
    quiet: bool
) -> bool:
    """Resolve the file path and apply its patch actions."""
    original_path = patch['file_path']

    file_path = resolve_file_path(work_dir, original_path)

    if file_path is None:
        log_error(f"   File not found or ambiguous: {original_path}")
        return False

    full_path = os.path.join(work_dir, file_path)

    log(f"  Patching: {file_path}", Colors.YELLOW, quiet)

    try:
        with open(full_path, 'r', encoding='utf-8') as f:
            lines = [
                line.rstrip('\n\r')
                for line in f.readlines()
            ]

    except Exception as e:
        log_error(f"   Failed to read file: {e}")
        return False

    # Work on a copy so failed patches do not partially modify
    # the original file in memory or on disk.
    working_lines = lines[:]

    for i, action in enumerate(patch['actions']):
        action_type = action['type']

        if action_type == 'REPLACE':
            result = apply_replace(working_lines, action, quiet)

        elif action_type == 'FIND_REPLACE':
            result = apply_find_replace(working_lines, action, quiet)

        elif action_type == 'PATCH':
            result = apply_patch(working_lines, action, quiet)

        else:
            log_error(f"   Unknown action type: {action_type}")
            return False

        if result is None:
            log_error(f"   Hunk failed at action {i + 1}")
            return False

        working_lines = result

    if working_lines == lines:
        log("   No changes required", Colors.YELLOW, quiet)
        return True

    try:
        with open(full_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(working_lines) + '\n')

        log("  File patched successfully", Colors.GREEN, quiet)

    except Exception as e:
        log_error(f"  Failed to write file: {e}")
        return False

    return True


def main():
    parser = argparse.ArgumentParser(
        description='Smalipatcher: Apply patches to smali files',
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        'work_dir',
        help='Root directory containing smali files'
    )

    parser.add_argument(
        'patch_file',
        help='Path to .smalipatch file'
    )

    parser.add_argument(
        '-q',
        '--quiet',
        action='store_true',
        help='Quiet mode (only show errors)'
    )

    args = parser.parse_args()

    Colors.init()

    if not os.path.isdir(args.work_dir):
        log_error(f"ERROR: Directory not found: {args.work_dir}")
        sys.exit(1)

    if not os.path.isfile(args.patch_file):
        log_error(f"ERROR: Patch file not found: {args.patch_file}")
        sys.exit(1)

    try:
        with open(args.patch_file, 'r', encoding='utf-8') as f:
            lines = [
                line.rstrip('\n\r')
                for line in f.readlines()
            ]

    except Exception as e:
        log_error(f"ERROR: Failed to read patch file: {e}")
        sys.exit(1)

    patches = parse_smalipatch(lines)

    if not patches:
        log_error("ERROR: No valid patches found")
        sys.exit(1)

    log(
        f"Found {len(patches)} file(s) to patch",
        Colors.BLUE,
        args.quiet
    )

    log("=" * 50, '', args.quiet)

    success_count = 0

    for patch in patches:
        if apply_patch_to_file(args.work_dir, patch, args.quiet):
            success_count += 1

        log("", '', args.quiet)

    log("=" * 50, '', args.quiet)

    if success_count == len(patches):
        log(
            f"Success: {success_count}/{len(patches)} files patched",
            Colors.GREEN,
            args.quiet
        )
        sys.exit(0)

    log_error(
        f"Failed: {success_count}/{len(patches)} files patched"
    )
    sys.exit(1)


if __name__ == '__main__':
    main()