{
  ssh = {
    fingerprint = "SHA256:OK+jESkjZj6sA4mmZQ78cGAQPvoA45G5luINRBL+90g";
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNjIO2jinm2iNpJ3Wkib5FaLwQhcBPcRyPwxoeZQgfb";
  };

  yubikeys = [
    { serial = "35686149"; description = "YubiKey 5C Nano (primary)"; }
    { serial = "18445889"; description = "YubiKey 5C (secondary)"; }
  ];

  gpg = {
    fingerprint = "1818334CEAC35348ED5E30F5DD40CEDB2EEAD4A4";
    publicKey = ''
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      mDMEaas1zBYJKwYBBAHaRw8BAQdAzo/VQe7OVIttY52VWqrE8ETcKHwmOJZ6yFdE
      RzEyD7y0J0x1Y2FzIE1hcmNvbG9uZ28gPGx1Y2FzQG1hcmNvbG9uZ28uZGV2PoiQ
      BBMWCgA4FiEEGBgzTOrDU0jtXjD13UDO2y7q1KQFAmmrNcwCGwEFCwkIBwIGFQoJ
      CAsCBBYCAwECHgECF4AACgkQ3UDO2y7q1KSqWgEAz08uo8qaIpuZr7Rpit1hUp+x
      o6emJTHeVrcCgDqkNSgA/3McMqwcYNSGNBwEK/q6ZfoRpcjpQMS6aDMrVt4C+vMN
      uDMEaas2eBYJKwYBBAHaRw8BAQdAUwyehw4UmNUJ0smT2pNDxO9NPHz9tklktr52
      gzaRmfWI7wQYFgoAIBYhBBgYM0zqw1NI7V4w9d1Aztsu6tSkBQJpqzZ4AhsCAIEJ
      EN1Aztsu6tSkdiAEGRYKAB0WIQTED640/6L6mglZ4MlT7aY1k48NjwUCaas2eAAK
      CRBT7aY1k48Nj8GoAP4rH4eyB1/rF0frpA+f+x8LXaDbA7lwa8Yf7/8+MKKz+gEA
      8PCiYfHpYcGTukmDUjVBeO3KJAzVqqlMLTdOcNR1LQRIxAEAjyGsQSqe2WcfOpaA
      3DzbKUjzAjQycRAhzfr3lZBb+xYBAJP3kC20ya0Ohc0gPFFZDHyXsKSLBQaZcLwY
      +TVYYKMHuDgEaas2kRIKKwYBBAGXVQEFAQEHQO/BDJHphHS3R+UjddECPRTl2RLQ
      ixGwwtFzNn+viARjAwEIB4h4BBgWCgAgFiEEGBgzTOrDU0jtXjD13UDO2y7q1KQF
      AmmrNpECGwwACgkQ3UDO2y7q1KSajAD+PMWin/g1jpMvxaBsTzX9gCis2L4+XFSk
      kbi20h5mE9YA+wcnzx/pzvGAToOym9QT55aWKLvUbaMcbmQkZ79pNSAMuDMEaas2
      qBYJKwYBBAHaRw8BAQdA02Mg7aOKebaI2kndaSJvkVovBCFwE9xHI/DGh5lCB9uI
      eAQYFgoAIBYhBBgYM0zqw1NI7V4w9d1Aztsu6tSkBQJpqzaoAhsgAAoJEN1Aztsu
      6tSkdpYA/35Yrdt6C5Y95gd6YaTucE4IXGsr8w7OMKUzFAaL6fShAP9OJEop3aar
      yEQmIIqdASiFqVVmVJaJ+2QwtjQNKUx6AQ==
      =5cyG
      -----END PGP PUBLIC KEY BLOCK-----
    '';
  };
}
