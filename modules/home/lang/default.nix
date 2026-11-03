# Language toolchains: lang.<name>.enable each (set by the profiles).
{
  imports = [
    ./dotnet.nix
    ./go.nix
    ./nix.nix
    ./nodejs.nix
    ./python.nix
  ];
}
