# Language toolchains; each file keeps its own gate.
{
  imports = [
    ./dotnet.nix
    ./go.nix
    ./nix.nix
    ./nodejs.nix
    ./python.nix
  ];
}
