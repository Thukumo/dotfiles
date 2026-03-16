# Custom Options Tree
Generated on 2026-03-16 21:25:36

- **custom**
  - **desktop**
    - **pipewire**
      - `enable` (Default: `true`): No description
    - **sunshine**
      - `enable` (Default: `false`): Whether to enable .
  - **hardware**
    - **disk**
      - **disko**
        - `ESPSize` (Default: `"2G"`): No description
        - `diskName` (Default: `No default`): No description
        - `enable` (Default: `true`): No description
        - `swapSize` (Default: `No default`): No description
      - **fstrim**
        - `enable` (Default: `true`): No description
      - **snapshot**
        - `enable` (Default: `false`): No description
    - **fwupdmgr**
      - `enable` (Default: `true`): No description
    - **gpu**
      - **nvidia**
        - `enable` (Default: `false`): Whether to enable nvidia GPU.
    - **keybind**
      - `deviceIds` (Default: `[]`): List of keyboard device IDs to apply keybindings to. Use '*' for all keyboards.
      - `enable` (Default: `true`): No description
    - **secure-boot**
      - `enable` (Default: `false`): Whether to enable Secure Boot with Lanzaboote.
      - **tpm2-totp**
        - `enable` (Default: `true`): Enable TPM2 TOTP support
      - **tpm2-unlock**
        - `enable` (Default: `true`): Enable TPM2 LUKS unlocking
        - `luksDevice` (Default: `null`): The name of the LUKS device to apply TPM2 unlock settings to
    - **tune**
      - **ananicy**
        - `enable` (Default: `true`): No description
      - **auto-cpufreq**
        - `enable` (Default: `true`): No description
      - **bpftune**
        - `enable` (Default: `true`): No description
      - **earlyoom**
        - `enable` (Default: `false`): Whether to enable earlyoom.
      - **ksm**
        - `enable` (Default: `true`): No description
        - `enableForAll` (Default: `false`): Whether to enable Enable ksm for all.
      - **powertop**
        - `enable` (Default: `true`): No description
      - **zswap**
        - `enable` (Default: `true`): No description
  - **network**
    - **cloudflare-warp**
      - `enable` (Default: `false`): Whether to enable Cloudflare Warp.
    - **mycelium**
      - `enable` (Default: `true`): No description
    - **wait-online**
      - `enable` (Default: `false`): Whether to enable NetworkManager-wait-online.
    - **zapret**
      - `enable` (Default: `false`): Whether to enable Zapret.
  - **secrets**
    - `extraIdentityPaths` (Default: `[]`): Additional identity paths for age encryption
  - **users** (User Options)
    - **_module**
      - `args` (Default: `No default`): Additional arguments passed to each module in addition to ones
like `lib`, `config`,
and `pkgs`, `modulesPath`.

This option is also available to all submodules. Submodules do not
inherit args from their parent module, nor do they provide args to
their parent module or sibling submodules. The sole exception to
this is the argument `name` which is provided by
parent modules to a submodule and contains the attribute name
the submodule is bound to, or a unique generated name if it is
not bound to an attribute.

Some arguments are already passed by default, of which the
following *cannot* be changed with this option:
- {var}`lib`: The nixpkgs library.
- {var}`config`: The results of all options after merging the values from all modules together.
- {var}`options`: The options declared in all modules.
- {var}`specialArgs`: The `specialArgs` argument passed to `evalModules`.
- All attributes of {var}`specialArgs`

  Whereas option values can generally depend on other option values
  thanks to laziness, this does not apply to `imports`, which
  must be computed statically before anything else.

  For this reason, callers of the module system can provide `specialArgs`
  which are available during import resolution.

  For NixOS, `specialArgs` includes
  {var}`modulesPath`, which allows you to import
  extra modules from the nixpkgs package tree without having to
  somehow make the module aware of the location of the
  `nixpkgs` or NixOS directories.
  ```
  { modulesPath, ... }: {
    imports = [
      (modulesPath + "/profiles/minimal.nix")
    ];
  }
  ```

For NixOS, the default value for this option includes at least this argument:
- {var}`pkgs`: The nixpkgs package set according to
  the {option}`nixpkgs.pkgs` option.

      - `check` (Default: `true`): Whether to check whether all option definitions have matching declarations.
      - `freeformType` (Default: `null`): If set, merge all definitions that don't have an associated option
together using this type. The result then gets combined with the
values of all declared options to produce the final `
config` value.

If this is `null`, definitions without an option
will throw an error unless {option}`_module.check` is
turned off.

      - `specialArgs` (Default: `No default`): Externally provided module arguments that can't be modified from
within a configuration, but can be used in module imports.

    - **account**
      - `userConfig` (Default: `{}`): Attribute set merged into users.users.<name>.
    - **desktop**
      - **activate-linux**
        - `enable` (Default: `false`): Whether to enable activate-linux watermark.
      - **apps**
        - **blender**
          - `enable` (Default: `false`): Whether to enable Blender.
        - **bottles**
          - `enable` (Default: `false`): Whether to enable Bottles.
        - **chromium**
          - `enable` (Default: `false`): Whether to enable Chromium.
        - **discord**
          - `enable` (Default: `false`): Whether to enable Discord.
        - **gnome-disk-utility**
          - `enable` (Default: `false`): Whether to enable GNOME Disk Utility.
        - **google-chrome**
          - `enable` (Default: `false`): Whether to enable Google Chrome.
        - **libreoffice**
          - `enable` (Default: `false`): Whether to enable LibreOffice.
        - **localsend**
          - `enable` (Default: `false`): Whether to enable LocalSend.
        - **mattermost-desktop**
          - `enable` (Default: `false`): Whether to enable Mattermost Desktop.
        - **prismLauncher**
          - `enable` (Default: `false`): Whether to enable Discord.
        - **qutebrowser**
          - `enable` (Default: `false`): Whether to enable qutebrowser.
        - **rquickshare**
          - `enable` (Default: `false`): Whether to enable RQuickShare.
        - **steam**
          - `enable` (Default: `false`): Whether to enable Steam.
        - **thunar**
          - `enable` (Default: `false`): Whether to enable Thunar.
        - **zoom**
          - `enable` (Default: `false`): Whether to enable Zoom.
      - `de` (Default: `null`): Desktop environment or window manager to use
      - `enable` (Default: `false`): Whether to enable desktop environment.
      - **hyprlock**
        - `enable` (Default: `true`): No description
      - `ime` (Default: `null`): Input method engine to use
      - `launcher` (Default: `null`): Application launcher to use
      - `terminal` (Default: `null`): Terminal emulator to use
      - **vr**
        - `enable` (Default: `false`): Whether to enable VR support.
    - **dev**
      - **aider**
        - `enable` (Default: `false`): Whether to enable aider.
      - **antigravity**
        - `enable` (Default: `false`): Whether to enable Google Antigravity.
      - **gns3**
        - `enable` (Default: `false`): Whether to enable gns3.
      - **ollama**
        - `enable` (Default: `false`): Whether to enable ollama.
        - `host` (Default: `"127.0.0.1"`): The host address to bind to.
        - `loadModels` (Default: `[]`): List of ollama models to pull on startup.
        - `package` (Default: `"/nix/store/snxspr77rs2ffw5dsxqjqbn56w644ndr-ollama-0.17.7"`): The ollama package to use.
      - **opencode**
        - `enable` (Default: `false`): Whether to enable opencode.
        - `models` (Default: `[]`): No description
      - **podman**
        - `enable` (Default: `false`): Whether to enable podman.
      - **unityhub**
        - `enable` (Default: `false`): Whether to enable Unity Hub.
    - `dotfilesPath` (Default: `null`): Path to dotfiles directory (relative to home). Enables NixOS management aliases when set.
    - `email` (Default: `null`): User's email address for git configuration and other uses
    - **network**
      - **dlna**
        - `enable` (Default: `false`): Whether to enable DLNA Server for this user.
        - `mediaDirs` (Default: `[]`): Media directories for this user.
Must be prefixed with V, P, or A followed by a comma (e.g., "V,path/to/video").
Relative paths are resolved to the user's home.

      - **globalProtect**
        - `enable` (Default: `false`): Whether to enable GlobalProtect VPN.
    - **persistence**
      - `directories` (Default: `[]`): Additional directories to persist for this user
      - `files` (Default: `[]`): Additional files to persist for this user
    - **secrets**
      - `secretKey` (Default: `null`): Path to user's secret key for age encryption (relative to /persist)
