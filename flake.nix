{
  description = "Dev environment for openai-apps-sdk-examples (Node + Python)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "ngrok"
            ];
          };
        };

        # Node 20 LTS satisfies Node 18+ requirement
        nodejs = pkgs.nodejs_20;

        # Python 3.11 matches README guidance (3.10+)
        python = pkgs.python311;

        commonPackages = with pkgs; [
          git
          pnpm
          nodejs
          python
          uv
          ngrok
          pre-commit
        ];

        corepackHook = "";

        pythonHelp = ''
          echo "Python tips:"
          echo "  python -m venv .venv && source .venv/bin/activate"
          echo "  pip install -r pizzaz_server_python/requirements.txt"
          echo "  pip install -r solar-system_server_python/requirements.txt"
          echo "  uvicorn pizzaz_server_python.main:app --port 8000"
          echo "  uvicorn solar-system_server_python.main:app --port 8000"
        '';
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = commonPackages;
            shellHook = ''
              export COREPACK_ENABLE=0
              echo "Loaded default dev shell (Node + Python)."
              echo "Node: pnpm is available from nixpkgs."
              echo "  pnpm install"
              echo "  pnpm run dev | build | serve"
              ${pythonHelp}
            '';
          };

          node = pkgs.mkShell {
            packages = with pkgs; [ pnpm nodejs git pre-commit ngrok ];
            shellHook = ''
              export COREPACK_ENABLE=0
              echo "Loaded Node-only shell."
              echo "  pnpm install"
              echo "  pnpm run dev | build | serve"
            '';
          };

          python = pkgs.mkShell {
            packages = with pkgs; [ python git pre-commit uv ngrok ];
            shellHook = ''
              echo "Loaded Python-only shell."
              ${pythonHelp}
            '';
          };
        };

        formatter = pkgs.alejandra;
      }
    );
}
