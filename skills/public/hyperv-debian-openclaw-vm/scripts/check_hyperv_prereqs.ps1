param()

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$edition = (Get-ComputerInfo).WindowsEditionId
$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
$sys = systeminfo
$requirements = $sys | Select-String "Hyper-V Requirements|Virtualization Enabled In Firmware|Second Level Address Translation|Data Execution Prevention"

[pscustomobject]@{
  IsAdministrator = $isAdmin
  WindowsEdition = $edition
  HyperVFeatureState = $hyperv.State
  RestartRequired = $hyperv.RestartRequired
  HyperVLines = ($requirements | ForEach-Object { $_.Line.Trim() }) -join "; "
} | Format-List
