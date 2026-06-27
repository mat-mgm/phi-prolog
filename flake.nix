{
  description = "A unified Prolog physics solver using CLP(R), symbolic algebra, and A* path planning.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        phi = pkgs.writeShellScriptBin "phi" ''
          exec ${pkgs.swi-prolog}/bin/swipl -s ${./phi.pl} "$@"
        '';
        phiAnim = pkgs.writeShellScriptBin "phi-anim" ''
          exec ${pkgs.swi-prolog}/bin/swipl -s ${./phi_anim.pl} -- "$@"
        '';
      in
      {
        packages.default = phi;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.swi-prolog
            phi
            phiAnim
          ];

          shellHook = ''
            echo "=========================================================="
            echo "  Welcome to phi: The Unified Prolog Physics Solver Env!"
            echo "=========================================================="
            echo "To run the test suite:"
            echo "  phi -g 'run_tests, halt.'"
            echo ""
            echo "To start the interactive REPL with custom prompt φ:"
            echo "  phi"
            echo ""
            echo "To run the interactive physics animation dashboard:"
            echo "  phi-anim"
            echo "=========================================================="
          '';
        };
      }
    );
}
