param(
  [string]$VmName = "Debian-Desktop",
  [string]$GuestIp = ""
)

$ErrorActionPreference = "Stop"

$vm = Get-VM -Name $VmName
$cpu = Get-VMProcessor -VMName $VmName
$disks = Get-VMHardDiskDrive -VMName $VmName |
  Select-Object ControllerNumber, ControllerLocation, Path
$dvd = Get-VMDvdDrive -VMName $VmName |
  Select-Object ControllerNumber, ControllerLocation, Path
$fw = Get-VMFirmware -VMName $VmName
$net = Get-VMNetworkAdapter -VMName $VmName

$report = [ordered]@{
  Name = $vm.Name
  State = $vm.State.ToString()
  Generation = $vm.Generation
  DynamicMemoryEnabled = $vm.DynamicMemoryEnabled
  MemoryStartupGB = [math]::Round($vm.MemoryStartup / 1GB, 2)
  ProcessorCount = $cpu.Count
  Disks = $disks
  Dvd = $dvd
  SecureBootTemplate = $fw.SecureBootTemplate
  SwitchName = $net.SwitchName
  GuestIPs = $net.IPAddresses
}

if ($GuestIp) {
  $report["SSH22"] = (Test-NetConnection $GuestIp -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded
  $report["RDP3389"] = (Test-NetConnection $GuestIp -Port 3389 -WarningAction SilentlyContinue).TcpTestSucceeded
}

$report | ConvertTo-Json -Depth 6
