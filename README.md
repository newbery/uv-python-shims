
# Project: uv python shims

A small, pyenv-style shim layer for `python` that delegates interpreter
resolution to `uv`.

The goal is to let you type `python`, `python3.11`, etc. and have it resolve
to a uv-managed python consistent with your project’s `.python-version` 
(and/or uv’s project discovery), without needing pyenv.

This project provides:

- `python` — a shim script that intercepts `python`/`python3.*` invocations
  and resolves an appropriate interpreter using `uv python find`.
- `install.bash` — an installer that copies the shim to `~/.local/uv-python-shims/`
  and creates symlinks for `python3` and a set of `python3.X` names.
- `tests/` — a lightweight bash test harness with mock `uv` + mock “python”
  executables.

References:

- `pyenv`  
  https://github.com/pyenv/pyenv

- `uv python find`  
  https://docs.astral.sh/uv/concepts/python-versions/#finding-a-python-executable


## The main shim (`./python`)

**Requires:** `bash` and `uv` installed and on your `PATH`

The shim runs `uv python find` to locate the best Python interpreter for the current
working directory:
  
- The find operation first looks for any python version constraints defined
  within a `.python-version` file or a project/workspace `pyproject.toml` file
  within the current directory or any parent directories.

- It then searches the following locations **in order** until it finds the
  first available python that satisfies the version constraints (or the first
  one found if there are no constraints):
  1. Closest non-activated virtual environment (activated environments bypass
     the shim entirely so they are always selected with no version constraints).
  2. UV-managed python installations in order from newest to oldest versions.
  3. The first suitable python found on the `PATH`.

- If a suitable python is found, that python is executed via its absolute path.
  If a suitable python can NOT be found, the script will exit and display the
  error message given by uv.

If the shim is invoked via a symlink with a versioned name like `python3.10`
or `python3.14`, it enforces that **major.minor**. It does this by first checking
what `uv` would pick by default and if the resolved interpreter does not match
the requested `3.X`, it reruns `uv python find 3.X` and uses that interpreter instead.

When invoking `uv` and executing the resolved python interpreter, the shim avoids
recursion by removing the shim directory from `PATH`.

There are a number of possible configuration flags that can modify the behavior
of `uv python find`. See the commented-out section near the top of the shim script
and uncomment the flags desired to control python discovery.


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

- bash: `~/.bashrc` (and/or `~/.bash_profile`)
- zsh: `~/.zshrc`

Then restart your shell, or run the export line once in your current session.

**Windows PATH:** If you install this in a Windows environment with bash support
(Git Bash / MSYS2 / Cygwin / WSL), be aware that the bash shell PATH update
suggested above will affect bash sessions only. To use from PowerShell/cmd,
you may also need to add the directory to Windows PATH.


### Verify result

```bash
which python
which python3.11
python --version
python3.11 --version
```

If you have a `.python-version` in a directory, try running from inside that
directory and from a subdirectory to confirm ***.python-version discovery***
behaves as expected.

If you have a project or workspace defined with a `pyproject.toml` that includes
a `requires-python` field, try running within that project directory or from a
subdirectory to confirm ***project/workspace discovery*** behaves as expected.

If you have a non-activated virtual environment installed in a `.venv` subdirectory
of a project, try running within the project directory or a subdirectory of that
project to confirm ***virtual environment discovery*** behaves as expected.


### Installer knobs

You can override the install destination or installer pacing:

```bash
DEST_DIR="$HOME/.local/uv-python-shims" bash ./install.bash
PAUSE=0 bash ./install.bash
PAUSE=0.25 bash ./install.bash
```

You can also change which `python3.X` symlinks are created by setting `MINOR_VERSIONS`
and instead of symlinks the installer can create copies or wrapper scripts:

```bash
MINOR_VERSIONS="10 11 12" bash ./install.bash
SHIM_MODE=copy bash ./install.bash
SHIM_MODE=wrapper bash ./install.bash
```

Before installing the shims, the installer wipes the target directory. This is
done to allow for easy updates and experimentation. There are guardrails to
help prevent unintentional destructive wipes. If the target directory looks fishy
or unexpected items are seen in the target directory, the script will exit
with an error message. Set `UV_PYTHON_SHIMS_FORCE` to override the guardrails:

```bash
UV_PYTHON_SHIMS_FORCE=1 bash ./install.bash
```


## Running tests

The tests are written in bash and do **not** require a real `uv` install.

They work by:

- copying the shim under test into a temp directory
- placing mock stubs on `PATH` (`tests/bin/uv`, plus fake interpreters)
- asserting calls/behavior via logs and captured output

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
colleagues on a non-uv managed project.

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


## Does this work with 'uv', 'hatch', 'poetry', 'pyenv', pixi', and 'pipx'?

Many tools will "just work" as long as they select the python found from the current
`PATH`. Some tools can be helped along to do this more consistently.

- **uv:** In most cases, `uv` will by default either attempt to use the python
  shim found from `PATH` or follow the same python discovery heuristic that the
  shim uses.  

- **hatch:** Set `HATCH_PYTHON=python` in your environment to tell hatch to
  default to using the python shim found from `PATH`. 

- **poetry:** Set `poetry config virtualenvs.prefer-active-python true --global`
  to configure poetry to default to using the python shim found from `PATH`.

- **pyenv:** The `uv-python-shims` solution is meant to be a **replacement**
  for `pyenv` shims. However, `uv` installs pre-built pythons while `pyenv`
  builds pythons from source. Pre-built python installation is much faster than
  building from source so they are preferred in most usecases. But if you still
  wish to build from source, you can continue using `pyenv` for this purpose.
  Just ensure that the `uv-python-shims` directory is found in the PATH **before**
  the `pyenv` shims directory. The `uv python find` will then be able to discover
  the pyenv-managed pythons as long as a suitable uv-managed python matching the
  version constraints is not found first.
  
- **pixi:** At this time, I know of no way to configure `pixi` to use a uv-managed python
  or to default to using the python shim found from `PATH`. The `pixi` tool
  manages pythons entirely within the pixi-managed virtual environment similar
  to how `conda` works.

- **pipx:** By default, the python selection when using `pipx` is deterministic
  and is not affected by the presence of `.python-version` files or virtual
  environments. This makes sense since having all your pipx-installed tools use
  different pythons can be surprising and difficult to manage. If despite this,
  you still want to use the dynamic python discovery made possible with these
  uv-python-shims, you can add something like the following to your shell
  startup file.
  ```
  export PIPX_DEFAULT_PYTHON="$(command -v python)
  ```
  
- **uv tool:** UV's equivalent to `pipx install` is `uv tool install`.
  Both install globally-accessible python-based tools in isolated virtual
  environments but there is a subtle difference between how the two select
  the python version installed in that environment. The `uv tool` mechanism
  appears to follow the same discovery heuristic as the rest of `uv` although
  it ignores version constraints defined in "local" configuration
  (local `.python-version` files or project/workspace `pyproject.toml` files).
  However the presence of an activated virtual environment or the existence
  of a non-activated virtual environment found in the current directory or
  parents may result in the selection of the python from that environment.
  This feels like a possible footgun if you expect the more deterministic
  behavior followed by `pipx`. To get the more deterministic pipx-like behavior,
  you can set `UV_PYTHON` environment variable to point to the desired default
  python path. UV_PYTHON can be either a version constraint or a path to a python
  executable. However this will set the default python for all `uv` operations
  which is likely undesirable. An alternative is just to define a special
  alias/function within your shell startup file just for `uv tool install`:
  ```
  uv-tool-install() { UV_PYTHON=[...] uv tool install "$@" }
  ```


## Notes and caveats

- **Caution:** `uv-python-shims` should NOT be used as a solution for auto-activating
  a project's virtual environment. It's not suitable for that task. This shim will
  only auto-discover the environment's python interpreter and will not directly
  expose any other executables within that environment. Either manually activate
  using the mechanism recommended for your environment manager, or possibly auto-activate
  the environment with a solution like `direnv` or `mise`.

- This shim delegates nearly all “what Python should I use?” logic to `uv`.
  If `uv` changes discovery rules or output formats, the shim may need tweaks.

- The `python3.X` behavior is intentionally “major.minor enforcement” (not micro/patch).

- If you also want shims for other tools (`pip`, `pytest`, etc.), it should be
  straightforward to add siblings that run `"$resolved_python" -m pip ...` or similar.
  I don't need this so I didn't bother adding it. Also check the "Caution"
  note above. If you need more than just a python shim, you probably would do better
  with a different solution.

## License

Licensed under the MIT License; see `LICENSE`.


