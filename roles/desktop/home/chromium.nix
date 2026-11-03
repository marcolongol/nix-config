{...}: {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--no-first-run"
      "--no-default-browser-check"
    ];
  };

  omninix.persistence.directories = [
    ".cache/chromium"
    ".config/chromium"
  ];
}
