# WindowsKnownIssues-Pwsh

Get the latest known issues from the Windows release health dashboard (Gathered from YAML files from [MicrosoftDocs/windows-itpro-docs/windows/release-information](https://github.com/MicrosoftDocs/windows-itpro-docs/tree/master/windows/release-information)) inside of a PowerShell console.

## Prerequisites

* PowerShell 5.1 / PowerShell Core 6 (And Above)
  * ***This was tested on PowerShell Core 6.2.***

## Notes

* This script can be published to an internal PowerShell repository.
* Only known issues can be gathered for all current Windows 10 releases and Windows Server 2016/2019.
  * Windows 7/8.1 and Windows Server 2008/2008 R2/2012/2012 R2 have YAML files available, but parsing them with the same regex returns nothing at this time.

## Basic Usage

```powershell
PS /> Get-WindowsKnownIssues.ps1 -WindowsVersion "Windows 10 1709"

PS /> Get-WindowsKnownIssues.ps1 -WindowsVersion "Windows 10 1809"

PS /> Get-WindowsKnownIssues.ps1 -WindowsVersion "Windows Server 2019"
```

The current options available to the `-WindowsVersion` parameter are:

* Windows 10 1809
* Windows 10 1803
* Windows 10 1709
* Windows 10 1703
* Windows 10 1607
* Windows 10 1507
* Windows Server 2019
* Windows Server 2016

As more releases become available, they will be added to the script as quickly as possible.

## To-Do List

- [x] Create `Get-WindowsKnownIssues.ps1` to gather known issues for Windows releases.
- [ ] Create `Get-WindowsResolvedIssues.ps1` to gather the resolved issues for Windows releases.
- [ ] Add more granular options, such as gathering more data regarding a known issue.
- [ ] Add error handling if `Invoke-WebRequest` fails or returns no data.
- [ ] Add support for version before Windows 10 and Windows Server 2016.
- [ ] Possibly turn the final scripts into a module. ***(?)***