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
      tC1MdWNhcyBNYXJjb2xvbmdvIDxsdWNhcy5tYXJjb2xvbmdvQHRlb2NvLmNvbT6I
      jgQTFgoANhYhBBgYM0zqw1NI7V4w9d1Aztsu6tSkBQJqS9XvAhsBBAsJCAcEFQoJ
      CAUWAgMBAAIeAQIXgAAKCRDdQM7bLurUpMQlAP9ycCYhtqHft6Wi6yM9lV0h/qDn
      u89nO3wogv0lqkcwfwD9EmB1i7nBZZ2f1oaEM9l9vNZOu1eDXc1jQiTUe/pRlgO4
      MwRpqzZ4FgkrBgEEAdpHDwEBB0BTDJ6HDhSY1QnSyZPak0PE7008fP22SWS2vnaD
      NpGZ9YjvBBgWCgAgFiEEGBgzTOrDU0jtXjD13UDO2y7q1KQFAmmrNngCGwIAgQkQ
      3UDO2y7q1KR2IAQZFgoAHRYhBMQPrjT/ovqaCVngyVPtpjWTjw2PBQJpqzZ4AAoJ
      EFPtpjWTjw2PwagA/isfh7IHX+sXR+ukD5/7HwtdoNsDuXBrxh/v/z4worP6AQDw
      8KJh8elhwZO6SYNSNUF47cokDNWqqUwtN05w1HUtBEjEAQCPIaxBKp7ZZx86loDc
      PNspSPMCNDJxECHN+veVkFv7FgEAk/eQLbTJrQ6FzSA8UVkMfJewpIsFBplwvBj5
      NVhgowe4OARpqzaREgorBgEEAZdVAQUBAQdA78EMkemEdLdH5SN10QI9FOXZEtCL
      EbDC0XM2f6+IBGMDAQgHiHgEGBYKACAWIQQYGDNM6sNTSO1eMPXdQM7bLurUpAUC
      aas2kQIbDAAKCRDdQM7bLurUpJqMAP48xaKf+DWOky/FoGxPNf2AKKzYvj5cVKSR
      uLbSHmYT1gD7ByfPH+nO8YBOg7Kb1BPnlpYou9RtoxxuZCRnv2k1IAy4MwRpqzao
      FgkrBgEEAdpHDwEBB0DTYyDto4p5tojaSd1pIm+RWi8EIXAT3Ecj8MaHmUIH24h4
      BBgWCgAgFiEEGBgzTOrDU0jtXjD13UDO2y7q1KQFAmmrNqgCGyAACgkQ3UDO2y7q
      1KR2lgD/flit23oLlj3mB3phpO5wTghcayvzDs4wpTMUBovp9KEA/04kSindpqvI
      RCYgip0BKIWpVWZUlon7ZDC2NA0pTHoB
      =UY+N
      -----END PGP PUBLIC KEY BLOCK-----
    '';
  };
}
