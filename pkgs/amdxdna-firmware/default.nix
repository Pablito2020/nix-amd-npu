{ lib
, fetchurl
, stdenvNoCC
}:

let
  # Firmware metadata from xdna-driver tools/info.json (v2.21.75)
  firmwares = [
    {
      name = "npu1";
      url = "https://gitlab.com/kernel-firmware/drm-firmware/-/raw/amd-ipu-staging/amdnpu/1502_00/npu.sbin.1.5.5.391";
      hash = "sha256-0T/5+5XGzqQCE/pp5aNGVSnwC7Z8CYTWI0PG4xgI+54=";
      installDir = "amdnpu/1502_00";
    }
    {
      name = "npu2";
      url = "https://gitlab.com/kernel-firmware/drm-firmware/-/raw/amd-ipu-staging/amdnpu/17f0_00/npu.sbin.0.7.22.185";
      hash = "sha256-6HvXFyB/qUDFAvgT42DHEsbYelPaU1j8HDHvynNu0zo=";
      installDir = "amdnpu/17f0_00";
    }
    {
      name = "npu4";
      url = "https://gitlab.com/kernel-firmware/drm-firmware/-/raw/amd-ipu-staging/amdnpu/17f0_10/1.7_npu.sbin.1.1.2.64";
      hash = "sha256-ftDyQvJTtYHrdcjIs0Y42S+6WYBjtjWlQb65SGkkVGk=";
      installDir = "amdnpu/17f0_10";
    }
    {
      name = "npu5";
      url = "https://gitlab.com/kernel-firmware/drm-firmware/-/raw/amd-ipu-staging/amdnpu/17f0_11/1.7_npu.sbin.1.1.2.65";
      hash = "sha256-PjyZbvHlYulu5MTZD6qfrxEyxy2jrxvPNdWSzDSQP+0=";
      installDir = "amdnpu/17f0_11";
    }
  ];

  sources = map (fw: {
    inherit (fw) name installDir;
    src = fetchurl {
      inherit (fw) url hash;
      name = "${fw.name}-npu.dev.sbin";
    };
  }) firmwares;

in stdenvNoCC.mkDerivation {
  pname = "amdxdna-firmware";
  version = "2.21.75";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
  '' + lib.concatMapStringsSep "\n" (fw: ''
    install -Dm444 ${fw.src} $out/lib/firmware/${fw.installDir}/npu.dev.sbin
  '') sources + ''

    runHook postInstall
  '';

  meta = with lib; {
    description = "Development firmware for AMD XDNA NPU (required by out-of-tree driver)";
    homepage = "https://gitlab.com/kernel-firmware/drm-firmware/-/tree/amd-ipu-staging/amdnpu";
    license = licenses.unfreeRedistributableFirmware;
    platforms = [ "x86_64-linux" ];
  };
}
