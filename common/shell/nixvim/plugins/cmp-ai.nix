{
  lib,
  myConfig,
  pkgs,
  ...
}:
let
  cfg = myConfig.dev.llama;
  fimCandidates = lib.filter (m: m.fim or false) cfg.models;
  fimNames = map (m: m.name) fimCandidates;
  fimModel =
    if cfg.fimModel == null then
      null
    else if lib.elem cfg.fimModel fimNames then
      lib.head (lib.filter (m: m.name == cfg.fimModel) fimCandidates)
    else
      throw "dev.llama.fimModel = \"${cfg.fimModel}\" は fim フラグ付きモデルにありません。候補: ${lib.concatStringsSep ", " fimNames}";
  cmpAiEnabled = cfg.enable && fimModel != null;
in
{
  programs.nixvim.plugins.cmp-ai = lib.mkIf cmpAiEnabled {
    enable = true;

    package = pkgs.vimUtils.buildVimPlugin {
      name = "cmp-ai";
      src = pkgs.fetchFromGitHub {
        owner = "tzachar";
        repo = "cmp-ai";
        rev = "996c76519fa92abab8071e3a732f4c07265eb554";
        hash = "sha256-XcXAtZYrWXoSp2wOPI3WJd2OqhoPpYT6CwrIEMYHGxU=";
      };
      postPatch = "patch -p1 < ${./cmp-ai-fim-infill.patch}";
      doCheck = false;
    };

    settings = {
      max_lines = 1000;
      run_on_every_keystroke = false;
      provider = "OpenAI";
      provider_options = {
        url = "http://${cfg.host}:${toString cfg.port}/v1/chat/completions";
        model = fimModel.name;
        api_key = "no-key";
        fim = true;
        max_tokens = 128;
        temperature = 0.1;
      };
    };
  };

  programs.nixvim.plugins.cmp.settings = lib.mkIf cmpAiEnabled {
    mapping."<C-x>" =
      "cmp.mapping(cmp.mapping.complete({ config = { sources = cmp.config.sources({ { name = 'cmp_ai' } }) } }), { 'i' })";
  };
}
