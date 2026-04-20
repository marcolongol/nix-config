{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  buildFHSEnv,
  # Runtime deps
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  coreutils,
  curl,
  dbus,
  expat,
  gdk-pixbuf,
  gjs,
  glib,
  gnome-keyring,
  gnugrep,
  gnused,
  gtk3,
  iproute2,
  iputils,
  iptables,
  libappindicator-gtk3,
  libnotify,
  libsecret,
  libdrm,
  libgbm,
  libxkbcommon,
  mesa,
  udev,
  networkmanager,
  networkmanager-openvpn,
  nspr,
  nss,
  pango,
  procps,
  which,
  wireguard-tools,
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
  libxtst,
  zip,
}:
let
  pname = "surfshark";
  version = "3.10.1";

  # Extract the .deb contents into the Nix store.
  # We intentionally skip autoPatchelfHook here because Surfshark bundles its
  # own Electron libs (libffmpeg.so etc.) that conflict with it.  The FHS
  # wrapper below provides all required system libraries at runtime instead.
  surfsharkUnpacked = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://ocean.surfshark.com/debian/pool/main/s/surfshark_${version}_amd64.deb";
      hash = "sha256-AEUH5NDIyyW21PZj38q8UGFj4gAuSuTr0lMg8ARLU5o=";
    };

    nativeBuildInputs = [ dpkg ];

    dontBuild = true;
    dontFixup = true; # no patching — FHS env handles runtime libs

    installPhase = ''
      runHook preInstall
      dpkg-deb -x "$src" "$out"
      runHook postInstall
    '';

    meta.license = lib.licenses.unfree;
  };

in
# Extend the buildFHSEnv derivation with a `data` attribute pointing to the
# unpacked .deb contents, so the NixOS module can reference the daemon scripts.
(buildFHSEnv {
  inherit pname version;

  name = pname; # buildFHSEnv uses `name` for the wrapper binary

  # Packages made available inside the FHS chroot at runtime.
  # We reference the outer function args directly to avoid a redundant `with`.
  targetPkgs = _: [
    # Electron / Chromium dependencies
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    mesa
    udev
    nspr
    nss
    pango
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
    libxtst

    # Surfshark declared dependencies (deduped against Electron set above)
    libnotify
    gjs
    networkmanager
    networkmanager-openvpn
    gnome-keyring
    libappindicator-gtk3
    libsecret
    curl
    zip
    dbus
    iproute2
    iputils
    iptables
    wireguard-tools

    # Needed by surfsharkd.js / surfsharkd2.js subprocess calls
    coreutils
    procps
    which
    gnugrep
    gnused
  ];

  # Bind the extracted .deb contents into the FHS environment so Surfshark
  # finds its files at the expected /opt/Surfshark path.
  extraBwrapArgs = [
    "--bind ${surfsharkUnpacked}/opt /opt"
  ];

  # Electron's chrome-sandbox requires setuid, which the Nix store cannot
  # provide.  --no-sandbox is the same workaround used by discord, slack, etc.
  runScript = "/opt/Surfshark/surfshark --no-sandbox";

  # Install a corrected desktop entry (Exec must point to the wrapper, not
  # /opt/Surfshark/surfshark) and symlink the bundled hicolor icons.
  extraInstallCommands = ''
    install -Dm644 <(sed 's|Exec=.*|Exec=surfshark %U|' \
      ${surfsharkUnpacked}/usr/share/applications/surfshark.desktop) \
      $out/share/applications/surfshark.desktop

    for size in 128x128 256x256 512x512; do
      install -Dm644 \
        ${surfsharkUnpacked}/usr/share/icons/hicolor/$size/apps/surfshark.png \
        $out/share/icons/hicolor/$size/apps/surfshark.png
    done
  '';

  meta = with lib; {
    description = "Surfshark VPN client for Linux";
    homepage = "https://surfshark.com/download/linux";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}) // { data = surfsharkUnpacked; }
