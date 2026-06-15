{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  wrapGAppsHook3,
  # Runtime libs (Electron GUI + node/pkg helper daemons)
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
  # Helper daemon / VPN engine PATH deps
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
  version = "10.1.0.53";

  # The agent hardcodes absolute /opt/Perimeter81 paths (it spawns its own
  # sibling binaries by that path) and needs to write into its install dir
  # (mkdir /opt/Perimeter81/yarkon). The NixOS module presents this exact path
  # as a writable overlay over the store, so the launchers target it directly.
  prefix = "/opt/Perimeter81";

  # The helper daemon + daemon-creator + p81daemonhelper are vercel/pkg bundles:
  # the JS payload is appended to the ELF, so they CANNOT be patchelf'd (it
  # corrupts the payload offsets). Instead we leave every binary untouched and
  # run them through nix-ld, which supplies /lib64/ld-linux + these libraries.
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

  # Tools the helper / engines shell out to (wg-quick, openvpn, charon call
  # `ip`, `iptables`, `modprobe`, etc. by name).
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

  # nix-ld env applied to every wrapped entrypoint. sudo's env_reset wipes
  # NIX_LD* on the GUI's `sudo p81-helper-daemon-creator` call, so each wrapper
  # must set them itself rather than relying on the global nix-ld variables.
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
      hash = "sha256-ijAmpUYmmi24JcTtLJu9iGHnRZNEmF61eHyXSAKUdmI=";
    };

    nativeBuildInputs = [
      makeWrapper
      wrapGAppsHook3
    ];

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true; # never patchelf — would corrupt the pkg payloads
    dontWrapGApps = true; # wrap the launcher manually below

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/Perimeter81"
      cp -a . "$out/opt/Perimeter81/"

      # Run the store binaries directly. The agent spawns its siblings and
      # writes state via ABSOLUTE /opt/Perimeter81 paths (not execPath-relative),
      # so the module's writable overlay at ${prefix} satisfies those at runtime
      # regardless of where the launcher execs from. GUI runs natively (NOT
      # sandboxed) so its `sudo p81-helper-daemon-creator start` can escalate.
      makeWrapper "$out/opt/Perimeter81/perimeter81" "$out/bin/${pname}" \
        --add-flags "--no-sandbox" \
        ${lib.escapeShellArgs nixLdArgs} \
        "''${gappsWrapperArgs[@]}"

      # Privileged helpers, symlinked into /usr/bin/p81-helper-daemon{,-creator}
      # by the NixOS module and invoked via sudo by the GUI.
      makeWrapper "$out/opt/Perimeter81/artifacts/daemon" \
        "$out/bin/${pname}-daemon" ${lib.escapeShellArgs nixLdArgs}
      makeWrapper "$out/opt/Perimeter81/artifacts/daemon-creator" \
        "$out/bin/${pname}-daemon-creator" ${lib.escapeShellArgs nixLdArgs}

      install -Dm644 /dev/stdin $out/share/applications/perimeter81.desktop <<EOF
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
      EOF

      runHook postInstall
    '';

    # Exposed so the NixOS module can feed the same set to programs.nix-ld for
    # GUI-spawned children (p81daemonhelper) that we don't wrap directly.
    passthru = {inherit runtimeLibs;};

    meta = with lib; {
      description = "Check Point Harmony SASE (Perimeter81) VPN agent";
      homepage = "https://www.checkpoint.com/harmony-sase/";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
