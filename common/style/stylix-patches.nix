{
  inputs,
  ...
}:
{
  # 使ってるStylixが古い(opencodeのテーマがおかしくなる対策)のでkmsconの設定でremovedなやつを踏む。
  # kmscon使ってないので、単に読み込まなければ良い
  disabledModules = [
    "${inputs.stylix}/modules/kmscon/nixos.nix"
  ];
}
