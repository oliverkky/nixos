{
  config,
  host,
  pkgs,
  ...
}:

let
  firmwareName = "mne007za1-60hz.bin";
  firmwarePath = "edid/${firmwareName}";
  laptopPanelEdid = pkgs.runCommand "mne007za1-edid" { } ''
    mkdir -p $out/lib/firmware/edid
    base64 -d > $out/lib/firmware/${firmwarePath} <<'EOF'
    AP///////wAObwwUAAAAAAAfAQS1HhN4Au6Vo1RMmSYPUFQAAAABAQEBAQEBAQEBAQEBAQEBtshAoLAITnAwIDYALrwQAAAYz4VAoLAITnAwIDYALrwQAAAYAAAA/gBDU09UIFQzCiAgICAgAAAA/gBNTkUwMDdaQTEtMwogAJw=
    EOF
  '';
in
{
  boot.kernelParams = [
    "drm.edid_firmware=${host.primaryMonitor}:${firmwarePath}"
  ];

  boot.initrd.extraFiles."lib/firmware/${firmwarePath}".source =
    "${laptopPanelEdid}/lib/firmware/${firmwarePath}";

  hardware.firmware = [ laptopPanelEdid ];
}
