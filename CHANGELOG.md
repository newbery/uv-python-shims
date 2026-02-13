
# Changelog

## 1.0.0
- Initial release.

## 1.1.0
- Added internal environment variable to signal major.minor override
  behavior in shims. Used by new optional wrapper shims.
- Added `SHIM_MODE=symlink|copy|wrapper` environment setting to control
  installer creation of major.minor shims.
- The installer now installs a manifest file to keep track of what it
  installed during the last run.
- The installer now wipes the target directory before installing shims.
  There are guardrails to help prevent unintentional destructive wipes.
  The guardrails can be overridden via `UV_PYTHON_SHIMS_FORCE` environ var.
