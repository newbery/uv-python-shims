
# Project: uv python shims

A small, pyenv-style shim layer for `python` that delegates interpreter
resolution to `uv`.

The goal is to let you type `python`, `python3.11`, etc. and have it resolve
to a uv-managed python consistent with your project’s `.python-version` 
(and/or uv’s project discovery), without needing pyenv.

This project provides:

* `python` — a shim script that intercepts `python`/`python3.*` invocations
  and resolves an appropriate interpreter using `uv python find`.
* `install.bash` — an installer that copies the shim to `~/.local/uv-python-shims/`
  and creates symlinks for `python3` and a set of `python3.X` names.
* `tests/` — a lightweight bash test harness with mock `uv` + mock “python”
  executables.

References:

* `pyenv`  
  https://github.com/pyenv/pyenv

* `uv python find`  
  https://docs.astral.sh/uv/concepts/python-versions/#finding-a-python-executable


## The main shim (`./python`)

**Requires:** `bash` and `uv` installed and on your `PATH`

* Runs `uv python find` to locate the best Python interpreter for the current
  working directory (uv walks upward looking for project metadata, including
  `.python-version`).

* If the shim is invoked via a symlink with a versioned name like `python3.10`
  or `python3.14`, it enforces that **major.minor**:

  * It checks what `uv` would pick by default.
  * If the resolved interpreter does not match the requested `3.X`, it reruns
    `uv python find 3.X` and uses that interpreter instead.

* Avoids recursion:

  * Removes the shim directory from `PATH` when invoking `uv` so `uv` won’t
    discover and re-run the shim as a candidate interpreter.
  * Executes the resolved interpreter via an absolute path.


## Install main shim and symlinks

**Requires:** `bash` (macOS default bash 3.2 is fine)

From the project root:

```bash
bash ./install.bash
```

By default, this installs to:

```text
~/.local/uv-python-shims/
```

Activate the shims by adding something like this to your shell startup file:

```bash
export PATH="$HOME/.local/uv-python-shims:$PATH"
```

Common locations:

* bash: `~/.bashrc` (and/or `~/.bash_profile`)
* zsh: `~/.zshrc`

Then restart your shell, or run the export line once in your current session.

### Verify result

```bash
which python
which python3.11
python --version
python3.11 --version
```

If you have a `.python-version` in a directory, try running from inside it and
from a subdirectory to confirm uv project discovery behaves as expected.

### Installer knobs

You can override the install destination or UI pacing:

```bash
DEST_DIR="$HOME/.local/uv-python-shims" bash ./install.bash
PAUSE=0 bash ./install.bash
PAUSE=0.25 bash ./install.bash
```

You can also change which `python3.X` links are created by setting `MINOR_VERSIONS`:

```bash
MINOR_VERSIONS="10 11 12" bash ./install.bash
```


## Running tests

The tests are written in bash and do **not** require a real `uv` install.

They work by:

* copying the shim under test into a temp directory
* placing mock stubs on `PATH` (`tests/bin/uv`, plus fake interpreters)
* asserting calls/behavior via logs and captured output

From the project root:

```bash
bash tests/run.bash
```


## Why did I make this?

The speed and ease of python interpreter installations and version management
via the 'uv' tool is very attractive but it doesn't natively support the python
shim behavior that I'm used to with 'pyenv'. That shim behavior is particularly
attractive if you need to work with multiple projects, many of which do not use 'uv'.

I appreciate the convenience of managing which pythons to use depending on
directory context and not locking myself into using 'uv' python invocation
semantics everywhere I need this. It's also a bit of a drag to explain why
I'm using 'uv' commands in a non-uv context when I'm collaborating with some
collegues on a non-uv managed project.

Keeping python version management conceptually separate from project and
virtualenv management is also a core good practice that I try to promote in
all my engagements.

There are others who have been asking for variations of combining the features
of pyenv-like python shims with uv-like python management. As of today,
Feb 9, 2026, I see the following open tickets that are related:

- In the `pyenv` project,  
  https://github.com/pyenv/pyenv/issues/2334

- In the `uv` project,  
  https://github.com/astral-sh/uv/issues/6265  
  https://github.com/astral-sh/uv/pull/7677

I'm guessing 'uv' will grow this feature eventually so my solution here is
probably just temporary... unless I don't like whatever 'uv' comes up with.

There are also alternative solutions possible using tools like
[direnv](https://direnv.net/) or [mise](https://mise.jdx.dev/). I already use
`direnv` a lot for auto-activating a project's virtualenv but I wanted the
python version switching to be less coupled from project management.


## Notes and caveats

* This shim delegates nearly all “what Python should I use?” logic to `uv`.
  If `uv` changes discovery rules or output formats, the shim may need tweaks.

* The `python3.X` behavior is intentionally “major.minor enforcement” (not micro/patch).

* If you also want shims for other tools (`pip`, `pytest`, etc.), it should be
  straightforward to add siblings that run `"$resolved_python" -m pip ...` or similar.
  I don't need this so I didn't bother adding it.

## License

Licensed under the MIT License; see `LICENSE`.


