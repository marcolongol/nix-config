{lib, ...}: {
  options = {
    persistentFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of user folders to persist under /persist/home/username";
    };
    persistentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of user files to persist under /persist/home/username";
    };
  };
}
