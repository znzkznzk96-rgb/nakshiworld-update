#!/usr/bin/env python3
"""Save an explicitly selected work checkpoint; never publishes a game release."""
import argparse, datetime, json, pathlib, subprocess, sys

def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--message', required=True)
    p.add_argument('--next', required=True, dest='next_step')
    p.add_argument('--status', choices=['in_progress', 'blocked', 'verified'], default='in_progress')
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('files', nargs='+', help='Explicit repository-relative files to include')
    a = p.parse_args()
    root = pathlib.Path(git('rev-parse', '--show-toplevel'))
    if pathlib.Path.cwd().resolve() != root.resolve():
        p.error('Run from the repository root.')
    branch = git('branch', '--show-current')
    if not branch.startswith('work/'):
        p.error('Checkpoint requires a work/* branch; main/deployment branches are forbidden.')
    if git('diff', '--cached', '--name-only'):
        p.error('Index already contains staged changes. Review/commit them first.')
    paths = list(dict.fromkeys(a.files + ['HANDOFF.md', 'WORK_STATE.json']))
    for name in paths:
        path = pathlib.Path(name)
        if path.is_absolute() or '..' in path.parts or name.startswith('-'):
            p.error('Use explicit repository-relative file paths.')
        if (root/path).is_dir() or (root/path).is_symlink():
            p.error('Directories and symlinks are not accepted; list individual files.')
        if any(part.lower() in ['.git', 'keys', '.env'] for part in path.parts) or path.suffix.lower() in ['.key', '.keystore', '.jks', '.pem']:
            p.error('Credential files must not be checkpointed.')
    if 'HANDOFF.md' not in git('diff', '--name-only').splitlines():
        p.error('Update HANDOFF.md with actual progress/test results before checkpointing.')
    state = json.loads((root/'WORK_STATE.json').read_text())
    state.update(status=a.status, work_branch=branch, next_step=a.next_step,
                 updated_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                 base_commit=git('rev-parse', 'HEAD'), checkpoint_commit='Containing commit; inspect git log')
    if a.dry_run:
        print(json.dumps({'branch':branch, 'files':paths, 'state':state}, ensure_ascii=False, indent=2));return
    (root/'WORK_STATE.json').write_text(json.dumps(state, ensure_ascii=False, indent=2)+'\n')
    subprocess.run(['git', 'add', '--']+paths, check=True)
    subprocess.run(['git', 'commit', '-m', a.message], check=True)
    subprocess.run(['git', 'push', '-u', 'origin', branch], check=True)
    sha = git('rev-parse', 'HEAD')
    remote = git('ls-remote', 'origin', 'refs/heads/'+branch).split()
    if not remote or remote[0] != sha:
        raise RuntimeError('Remote checkpoint verification failed; do not report saved.')
    print('REMOTE_CHECKPOINT_VERIFIED', branch, sha)

if __name__ == '__main__':
    try: main()
    except (subprocess.CalledProcessError, RuntimeError) as error:
        print('Checkpoint incomplete; inspect local/remote state before retrying:', error, file=sys.stderr)
        sys.exit(1)
