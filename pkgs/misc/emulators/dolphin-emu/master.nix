{ stdenv, fetchFromGitHub, makeWrapper, makeDesktopItem, pkgconfig, cmake, qt5
, bluez, ffmpeg, libao, libGLU_combined, pcre, gettext, libXrandr, libusb, lzo
, libpthreadstubs, libXext, libXxf86vm, libXinerama, libSM, libXdmcp, readline
, openal, udev, libevdev, portaudio, curl, alsaLib, miniupnpc, enet, mbedtls
, soundtouch, sfml, vulkan-loader ? null, libpulseaudio ? null

# - Inputs used for Darwin
, CoreBluetooth, cf-private, ForceFeedback, IOKit, OpenGL, libpng, hidapi }:

let
  desktopItem = makeDesktopItem {
    name = "dolphin-emu-master";
    exec = "dolphin-emu-master";
    icon = "dolphin-emu";
    comment = "A Wii/GameCube Emulator";
    desktopName = "Dolphin Emulator (master)";
    genericName = "Wii/GameCube Emulator";
    categories = "Game;Emulator;";
    startupNotify = "false";
  };
in stdenv.mkDerivation rec {
  name = "dolphin-emu-${version}";
  version = "2018-07-22";

  src = fetchFromGitHub {
    owner = "dolphin-emu";
    repo = "dolphin";
    rev = "7c2d2548a88abf9a5fa0bff52e00c57d093a9e19";
    sha256 = "0x9h8s6fa04vcdwaqgrd5jpbgadgpkj3m4g2w1mp97libvr7hpy4";
  };

  enableParallelBuilding = true;
  nativeBuildInputs = [ cmake pkgconfig ]
  ++ stdenv.lib.optionals stdenv.isLinux [ makeWrapper ];

  buildInputs = [
    curl ffmpeg libao libGLU_combined pcre gettext libpthreadstubs libpulseaudio
    libXrandr libXext libXxf86vm libXinerama libSM readline openal libXdmcp lzo
    portaudio libusb libpng hidapi miniupnpc enet mbedtls soundtouch sfml
    qt5.qtbase
  ] ++ stdenv.lib.optionals stdenv.isLinux [
    bluez udev libevdev alsaLib vulkan-loader
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    CoreBluetooth cf-private OpenGL ForceFeedback IOKit
  ];

  cmakeFlags = [
    "-DUSE_SHARED_ENET=ON"
    "-DENABLE_LTO=ON"
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    "-DOSX_USE_DEFAULT_SEARCH_PATH=True"
  ];

  # - Allow Dolphin to use nix-provided libraries instead of building them
  preConfigure = ''
    sed -i -e 's,DISTRIBUTOR "None",DISTRIBUTOR "NixOS",g' CMakeLists.txt
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    sed -i -e 's,if(NOT APPLE),if(true),g' CMakeLists.txt
    sed -i -e 's,if(LIBUSB_FOUND AND NOT APPLE),if(LIBUSB_FOUND),g' \
      CMakeLists.txt
  '';

  postInstall = ''
    cp -r ${desktopItem}/share/applications $out/share
    ln -sf $out/bin/dolphin-emu $out/bin/dolphin-emu-master
  '' + stdenv.lib.optionalString stdenv.isLinux ''
    wrapProgram $out/bin/dolphin-emu-nogui \
      --prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib
    wrapProgram $out/bin/dolphin-emu \
      --prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib
  '';

  meta = with stdenv.lib; {
    homepage = "http://dolphin-emu.org";
    description = "Gamecube/Wii/Triforce emulator for x86_64 and ARM";
    license = licenses.gpl2;
    maintainers = with maintainers; [ MP2E ];
    branch = "master";
    # x86_32 is an unsupported platform.
    # Enable generic build if you really want a JIT-less binary.
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}
