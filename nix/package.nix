{
  lib,
  stdenv,
  cmake,
  ninja,
  obs-studio,
  pipewire,
  pkg-config,
  libdrm,
  libGL,
}:
stdenv.mkDerivation {
  pname = "obs-pwvideo";
  version = "0.2.5";

  src = ./..;

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    obs-studio
    pipewire
    libdrm
    libGL
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=./lib"
    "-DCMAKE_INSTALL_DATADIR=./share"
  ];

  meta = {
    description = "OBS generic PipeWire video source";
    homepage = "https://github.com/tasokait/obs-pwvideo";
    maintainers = with lib.maintainers; [
      liquidnya
    ];
    license = lib.licenses.gpl2Plus;
    inherit (obs-studio.meta) platforms;
  };
}
