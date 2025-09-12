final: prev: {
  # Custom packages go here
  # Example:
  # myCustomPackage = final.callPackage ./packages/my-package.nix {};
  # hello = final.pkgs.stdenv.mkDerivation {
  #   pname = "demo-hello-world";
  #   version = "1.0.0";
  #   dontUnpack = true;
  #   buildInputs = [ final.pkgs.gcc ];
  #   buildPhase = ''
  #     echo '#include <stdio.h>' > hello.c
  #     echo 'int main() { printf("Hello, World!\n"); return 0; }' >> hello.c
  #     ${final.pkgs.gcc}/bin/gcc hello.c -o hello
  #   '';
  #   installPhase = ''
  #     mkdir -p $out/bin
  #     cp hello $out/bin/
  #   '';
  #   meta = with final.pkgs.lib; {
  #     description = "A simple Hello World program";
  #     homepage = "https://example.com/demo-hello-world";
  #     license = licenses.mit;
  #     maintainers = with maintainers; [ ];
  #     platforms = platforms.unix;
  #   };
  # };
}
