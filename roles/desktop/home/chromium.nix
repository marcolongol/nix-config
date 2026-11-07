{...}: {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--no-first-run"
      "--no-default-browser-check"
      "--enable-unsafe-webgpu"
    ];
  };

  omninix.persistence.directories = [
    ".cache/chromium"
    ".config/chromium"
  ];
}
