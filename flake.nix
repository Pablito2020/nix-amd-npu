{
  description = "AMD Ryzen AI NPU support for NixOS (XRT + XDNA driver)";

  inputs = {
    # Use fork with vitis-ai branch containing xrt, xrt-plugin-amdxdna, and NixOS module
    nixpkgs.url = "github:robcohen/nixpkgs/vitis-ai";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./parts/packages.nix
        ./parts/devshell.nix
        ./parts/nixos-module.nix
      ];

      # Overlay adds packages not yet in nixpkgs
      # XRT packages (xrt, xrt-plugin-amdxdna, xrt-amdxdna) come from nixpkgs fork
      flake.overlays.default = final: prev: {
        # Firmware and kernel driver (not yet in nixpkgs)
        amdxdna-firmware = final.callPackage ./pkgs/amdxdna-firmware { };

        # Vitis AI libraries
        unilog = final.callPackage ./pkgs/vitis-ai/unilog { };
        xir = final.callPackage ./pkgs/vitis-ai/xir {
          inherit (final) unilog;
        };
        target-factory = final.callPackage ./pkgs/vitis-ai/target-factory {
          inherit (final) unilog xir;
        };
        vart = final.callPackage ./pkgs/vitis-ai/vart {
          inherit (final) unilog xir target-factory;
          xrt = null;
        };
        trace-logging = final.callPackage ./pkgs/vitis-ai/trace-logging { };
        graph-engine = final.callPackage ./pkgs/vitis-ai/graph-engine {
          inherit (final) unilog xir vart xrt;
        };
        xaiengine = final.callPackage ./pkgs/vitis-ai/xaiengine { };
        dynamic-dispatch = final.callPackage ./pkgs/vitis-ai/dynamic-dispatch {
          inherit (final) xaiengine xrt;
        };

        # ONNX Runtime with VitisAI EP
        onnxruntime-vitisai = final.callPackage ./pkgs/onnxruntime-vitisai {
          inherit (final) xrt;
          inherit (prev) onnxruntime;
        };

        # MLIR-AIE for NPU kernel development
        mlir-aie = final.callPackage ./pkgs/mlir-aie { };

        # Whisper-IRON speech recognition
        whisper-iron = final.callPackage ./pkgs/whisper-iron {
          inherit (final) mlir-aie xrt-amdxdna;
        };

        # FastFlowLM NPU-optimized LLM runtime
        fastflowlm = final.callPackage ./pkgs/fastflowlm {
          inherit (final) xrt;
        };
      };

      perSystem = { system, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          # Note: XRT is Apache-2.0 licensed, no unfree components required
        };
      };
    };
}
