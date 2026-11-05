# Helpers for this configuration.
#
# Delivered via `specialArgs` (not `_module.args`): module `imports` are
# resolved before `config` exists, so anything used there must come from
# config-independent arguments. The config-dependent helpers
# (`mkForEachUsers`) therefore take `config` explicitly.
#
{ lib }:
let
  # Import all children of `dir` matching `pred` (pred: name -> type -> bool).
  mkImportChildren =
    dir: pred:
    map (name: toString dir + "/${name}") (lib.attrNames (lib.filterAttrs pred (builtins.readDir dir)));

  # Is this entry a regular `.nix` module (excluding `default.nix`)?
  isModuleFile = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";

  # A module directory is a directory with a default.nix. Data directories
  # must live outside the module tree; otherwise the missing entrypoint is
  # an error instead of being silently ignored.
  isModuleDir =
    dir: name: type:
    if type != "directory" then
      false
    else if builtins.pathExists (toString dir + "/${name}/default.nix") then
      true
    else
      throw "module directory ${toString dir}/${name} has no default.nix; move data outside the module tree or exclude it explicitly";

  # Import every subdirectory of `dir` (as <dir>/<name>/default.nix modules).
  mkImportSubdirs =
    dir: mkImportChildren dir (name: type: type == "directory" && isModuleDir dir name type);

  # Import every `.nix` module file and module subdirectory, excluding named
  # subdirectories. Exclusions are only for conditionally imported modules
  # such as `shell/private`.
  mkImportModules =
    dir: excludedDirs:
    mkImportChildren dir (
      name: type:
      isModuleFile name type
      || (type == "directory" && !builtins.elem name excludedDirs && isModuleDir dir name type)
    );

  mkEnabledOption =
    name:
    lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable ${name} (enabled by default).";
    };

  # Type for the per-user option `custom.users` (attrsOf submodule).
  # Each module extends it with only the fields it adds:
  # `options.custom.users = myLib.mkUserOption ({ config, ... }: { options.… = …; });`
  mkUserOption =
    defn:
    lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule defn);
    };

  # Whether any user in `custom.users` satisfies `cond`.
  anyUser = config: cond: lib.any cond (lib.attrValues config.custom.users);

  # Iterate only users explicitly present in `config.custom.users`.
  # This avoids evaluating conditions for users with no custom config,
  # and keeps condition mistakes as hard evaluation errors.
  mkForEachUsers =
    config: condition: content:
    lib.mkMerge (
      lib.mapAttrsToList (
        name: userCfg:
        let
          sysUser =
            if builtins.hasAttr name config.users.users then
              config.users.users.${name}
            else
              throw "custom.users.${name} is defined, but users.users.${name} does not exist (typo?)";

          user' = sysUser // {
            inherit name;
            custom = userCfg;
          };
        in
        lib.mkIf (sysUser.isNormalUser && (condition user')) {
          "${name}" = if builtins.isFunction content then content user' else content;
        }
      ) config.custom.users
    );
in
{
  inherit
    mkImportChildren
    isModuleFile
    mkImportSubdirs
    mkImportModules
    mkEnabledOption
    mkUserOption
    anyUser
    mkForEachUsers
    ;
}
