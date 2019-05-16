
<#PSScriptInfo

.VERSION 19.05.15

.GUID 34b70aa1-3c98-4ab1-b68e-7c79428f007e

.AUTHOR Tim Small

.COMPANYNAME Smalls.Online

.COPYRIGHT 2019

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
- Initial Release.

.PRIVATEDATA

#>

<#
.SYNOPSIS
    Get the current known issues for Windows and Windows Server.
.DESCRIPTION
    Get the latest known issues from Microsoft's Windows release health dashboard.
.PARAMETER WindowsVersion
    The version of Windows or Windows Server.
.EXAMPLE
    PS > Get-WindowsKnownIssues.ps1 -WindowsVersion "Windows 10 1803"
    
    Pulls the latest known issues posted about Windows 10 1803.
.NOTES
    Does not include support for Windows 7/8.1 or Windows Server 2008/2008 R2/2012/2012 R2.
#>
[CmdletBinding()]
param(
    [ValidateSet("Windows 10 1809", "Windows 10 1803", "Windows 10 1709", "Windows 10 1703", "Windows 10 1607", "Windows 10 1507", "Windows Server 2019", "Windows Server 2016")][string]$WindowsVersion = "Windows 10 1809"
)

begin {

    #Setting $StatusPageUri to the YAML document for the respective Windows version found on Microsoft's Docs GitHub.
    Write-Verbose "Windows version set to '$($WindowsVersion)'."
    switch ($WindowsVersion) {
        { ($PSItem -eq "Windows 10 1809") -or ($PSItem -eq "Windows Server 2019") } {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1809-and-windows-server-2019.yml"
        }

        "Windows 10 1803" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1803.yml"
        }

        "Windows 10 1709" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1709.yml"
        }

        "Windows 10 1703" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1703.yml"
        }

        { ($PSItem -eq "Windows 10 1607") -or ($PSItem -eq "Windows Server 2016") } {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1607-and-windows-server-2016.yml"
        }

        "Windows 10 1507" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1507.yml"
        }

        { ($PSItem -eq "Windows 8.1") -or ($PSItem -eq "Windows Server 2012 R2") } {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-8.1-and-windows-server-2012-r2.yml"
        }

        "Windows Server 2012" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-server-2012.yml"
        }

        { ($PSItem -eq "Windows 7") -or ($PSItem -eq "Windows Server 2008 R2") } {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-7-and-windows-server-2008-r2-sp1.yml"
        }

        "Windows Server 2008" {
            $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-server-2008-sp2.yml"
        }
    }

    #Setting the Regex expressions
    $StatusPageRegex = '- title: Known issues\n.*\n.*\n.*text:.\"((?s).*?)\"\n'
    $KnownIssuesTableRegex = "<tr><td><div id='.*?'><\/div><b>(?'issueTitle'.*?)<\/b><br>(?'issueDetails'.*?)<br>.*<\/td><td>OS Build (?'originalUpdateBuild'.*?)<br><br>(?'originalUpdateRelease'.*?)<br><a .*?>(?'originalUpdateKB'.*?)<\/a><\/td><td>(?'status'.*?)<br><a .*?>(?:(?'resolvedKB'KB.*?)|.*)<\/a><\/td><td>(?'lastUpdatedDate'.*)<br>(?'lastUpdatedTime'.*?) PT<\/td><\/tr>"

    $StatusPage = Invoke-WebRequest -Uri $StatusPageUri

    Write-Verbose "Parsing for the 'Known Issues' section in data."
    $KnownIssuesSection = ([regex]::Match($StatusPage.Content, $StatusPageRegex).Groups[1]).Value

    Write-Verbose "Parsing 'Known Issues' table."
    $KnownIssues = ([regex]::Matches($KnownIssuesSection, $KnownIssuesTableRegex))
}

process {

    Write-Verbose "Parsing data into object."
    $return = @()
    foreach ($Issue in $KnownIssues) {

        $Groups = $Issue | Select-Object -ExpandProperty "Groups"
    
        $Obj = New-Object -TypeName pscustomobject -Property @{
            "Title"                     = ($Groups | Where-Object -Property "Name" -EQ "issueTitle" | Select-Object -ExpandProperty "Value");
            "Details"                   = ($Groups | Where-Object -Property "Name" -EQ "issueDetails" | Select-Object -ExpandProperty "Value");
            "OriginalUpdateBuild"       = ($Groups | Where-Object -Property "Name" -EQ "originalUpdateBuild" | Select-Object -ExpandProperty "Value");
            "OriginalUpdateReleaseDate" = [convert]::ToDateTime(($Groups | Where-Object -Property "Name" -EQ "originalUpdateRelease" | Select-Object -ExpandProperty "Value"));
            "OriginalUpdateKB"          = ($Groups | Where-Object -Property "Name" -EQ "originalUpdateKB" | Select-Object -ExpandProperty "Value");
            "Status"                    = ($Groups | Where-Object -Property "Name" -EQ "status" | Select-Object -ExpandProperty "Value");
            "LastUpdated"               = [convert]::ToDateTime(("$($Groups | Where-Object -Property "Name" -EQ "lastUpdatedDate" | Select-Object -ExpandProperty "Value") $($Groups | Where-Object -Property "Name" -EQ "lastUpdatedTime" | Select-Object -ExpandProperty "Value")")).ToLocalTime()
        }

        if (($Groups | Where-Object -Property "Name" -EQ "resolvedKB" | Select-Object -ExpandProperty "Value")) {
            Add-Member -InputObject $Obj -MemberType NoteProperty -Name "ResolvedKB" -Value ($Groups | Where-Object -Property "Name" -EQ "resolvedKB" | Select-Object -ExpandProperty "Value")
        }

        $defaultOutput = "Title", "OriginalUpdateBuild", "OriginalUpdateKB", "Status", "LastUpdated"
        $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
        $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)
        Add-Member -InputObject $Obj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput

        $return += $Obj
    }
}

end {
    return $return
}