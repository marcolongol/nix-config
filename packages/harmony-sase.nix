{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  writeText,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libgbm,
  libnotify,
  libappindicator-gtk3,
  libsecret,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  vulkan-loader,
  xz,
  zlib,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  curl,
  iproute2,
  iptables,
  iputils,
  kmod,
  openssl,
  procps,
  coreutils,
  gnugrep,
  gnused,
  which,
  wireguard-tools,
}: let
  pname = "harmony-sase";
  version = "10.1.1.339";

  # Agent hardcodes absolute /opt/Perimeter81 paths; the NixOS module overlays that path writable.
  prefix = "/opt/Perimeter81";

  desktopItem = writeText "perimeter81.desktop" ''
    [Desktop Entry]
    Name=Harmony SASE
    Exec=${pname} %U
    Terminal=false
    Type=Application
    Icon=perimeter81
    StartupWMClass=Perimeter81
    Comment=Check Point Harmony SASE (Perimeter81) agent
    MimeType=x-scheme-handler/harmonysase;x-scheme-handler/perimeter81;
    Categories=Network;
  '';

  # pkg bundles can't be patchelf'd (corrupts the payload); run untouched via nix-ld.
  runtimeLibs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libgbm
    libnotify
    libappindicator-gtk3
    libsecret
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd # libudev + libsystemd (p81daemonhelper)
    vulkan-loader
    xz # liblzma — p81daemonhelper (since 10.1.1.339)
    zlib # libz — swglib.so plugin + osquery
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    stdenv.cc.cc.lib # libstdc++
  ];

  libPath = lib.makeLibraryPath runtimeLibs;
  loader = stdenv.cc.bintools.dynamicLinker;

  # Tools the helper/engines call by name.
  helperPath = lib.makeBinPath [
    iproute2
    iptables
    iputils
    kmod
    openssl
    curl
    procps
    coreutils
    gnugrep
    gnused
    which
    wireguard-tools # wg / wg-quick
  ];

  # sudo env_reset wipes NIX_LD*, so each wrapper sets them itself.
  nixLdArgs = [
    "--set"
    "NIX_LD"
    loader
    "--prefix"
    "NIX_LD_LIBRARY_PATH"
    ":"
    libPath
    "--prefix"
    "PATH"
    ":"
    helperPath
  ];
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://static.perimeter81.com/agents/linux/Perimeter81_${version}.tar.xz";
      hash = "sha256-mbP239SFKunMa/5PZ9m6LSUeZBTUo/I7Yyw8ZDytzPk=";
    };

    nativeBuildInputs = [makeWrapper];

    dontConfigure = true;
    dontBuild = true;
    # Fixup would strip/patchelf and corrupt the pkg payloads.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/Perimeter81"
      cp -a . "$out/opt/Perimeter81/"

      # Run store binaries directly; the module's overlay satisfies the absolute /opt paths.
      # GUI is not sandboxed so its `sudo p81-helper-daemon system-ctl start` can escalate.
      makeWrapper "$out/opt/Perimeter81/perimeter81" "$out/bin/${pname}" \
        --add-flags "--no-sandbox" \
        ${lib.escapeShellArgs nixLdArgs}

      # Privileged helper, symlinked to /usr/bin/p81-helper-daemon by the module; since 10.1.1.339 a multi-call binary.
      makeWrapper "$out/opt/Perimeter81/artifacts/daemon" \
        "$out/bin/${pname}-daemon" ${lib.escapeShellArgs nixLdArgs}

      install -Dm644 ${desktopItem} \
        $out/share/applications/perimeter81.desktop

      runHook postInstall
    '';

    # Exposed so the module can feed the same set to programs.nix-ld.
    passthru = {inherit runtimeLibs;};

    meta = with lib; {
      description = "Check Point Harmony SASE (Perimeter81) VPN agent";
      homepage = "https://www.checkpoint.com/harmony-sase/";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
