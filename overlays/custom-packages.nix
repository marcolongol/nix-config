final: prev: {
  # Inline custom package derivations go here.
  # Use this file for packages that are too simple to warrant their own file
  # in ../packages/, or for quick overrides of existing packages.
  #
  # Example:
  # hello-world = final.stdenv.mkDerivation {
  #   pname = "hello-world";
  #   version = "1.0.0";
  #   dontUnpack = true;
  #   buildPhase = ''
  #     echo '#include <stdio.h>' > hello.c
  #     echo 'int main() { printf("Hello, World!\n"); return 0; }' >> hello.c
  #     ${final.gcc}/bin/gcc hello.c -o hello
  #   '';
  #   installPhase = ''
  #     mkdir -p $out/bin
  #     cp hello $out/bin/
  #   '';
  #   meta = with final.lib; {
  #     description = "A simple Hello World program";
  #     license = licenses.mit;
  #     platforms = platforms.unix;
  #   };
  # };
}
