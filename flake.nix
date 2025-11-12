{
  description = "Dev environment for openai-apps-sdk-examples (Node + Python)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Node 20 LTS satisfies Node 18+ requirement
        nodejs = pkgs.nodejs_20;

        # Python 3.11 matches README guidance (3.10+)
        python = pkgs.python311;

        commonPackages = with pkgs; [
          git
          nodejs
          python
          uv
          ngrok
          pre-commit
        ];

        corepackHook = ''
          # Use Corepack (bundled with Node) to activate the pinned pnpm version
          export COREPACK_HOME="$PWD/.corepack"
          mkdir -p "$COREPACK_HOME"
          corepack enable >/dev/null 2>&1 || true
          # Pinned from package.json: packageManager: pnpm@10.13.1
          corepack prepare pnpm@10.13.1 --activate >/dev/null 2>&1 || true
        '';

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
            shellHook = corepackHook + ''
              echo "Loaded default dev shell (Node + Python)."
              echo "Node: use pnpm via Corepack (pinned)."
              echo "  pnpm install"
              echo "  pnpm run dev | build | serve"
              ${pythonHelp}
            '';
          };

          node = pkgs.mkShell {
            packages = with pkgs; [ nodejs git pre-commit ngrok ];
            shellHook = corepackHook + ''
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
