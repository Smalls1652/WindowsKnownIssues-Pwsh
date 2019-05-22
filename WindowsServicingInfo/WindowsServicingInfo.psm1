<#
.SYNOPSIS
    Get the current known issues for Windows and Windows Server.
.DESCRIPTION
    Get the latest known issues from Microsoft's Windows release health dashboard.
.PARAMETER WindowsVersion
    The version of Windows or Windows Server.
.EXAMPLE
    PS > Get-WindowsKnownIssues -WindowsVersion "Windows 10 1803"
    
    Pulls the latest known issues posted about Windows 10 1803.
.NOTES
    Does not include support for Windows 7/8.1 or Windows Server 2008/2008 R2/2012/2012 R2.
#>
function Get-WindowsKnownIssues {


    [CmdletBinding()]
    param(
        [ValidateSet("Windows 10 1903","Windows 10 1809", "Windows 10 1803", "Windows 10 1709", "Windows 10 1703", "Windows 10 1607", "Windows 10 1507", "Windows Server 2019", "Windows Server 2016")][string]$WindowsVersion = "Windows 10 1903"
    )

    begin {

        #Setting $StatusPageUri to the YAML document for the respective Windows version found on Microsoft's Docs GitHub.
        Write-Verbose "Windows version set to '$($WindowsVersion)'."
        switch ($WindowsVersion) {
            "Windows 10 1903" {
                $StatusPageUri = "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/master/windows/release-information/status-windows-10-1903.yml"
            }

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
}

<#
.SYNOPSIS
    Get Windows 10 feature update servicing info.

.DESCRIPTION
    Pulls information from Microsoft about Windows 10's lifecycle for major feature updates. Information includes: Version, Service Channel, Release Date, Build Number, Last Revision Date, and EoL dates for Consumer and Enterprise releases.

.PARAMETER ServicingChannel
    The servicing channel for Windows Update.

.PARAMETER WindowsVersion
    The Windows 10 feature update version number.

.EXAMPLE
    PS /> Get-WindowsServicingInfo -ServicingChannel "LTSB/LTSC"

    ServiceChannel    : Long-Term Servicing Channel (LTSC)
    Version           : 1809
    EnterpriseEolDate : 2029-01-09
    ConsumerEolDate   : 2024-01-09
    ReleaseDate       : 2018-11-13
    LastRevisionDate  : 2019-05-14
    BuildNumber       : 17763.503

    [...]

.EXAMPLE
    PS /> Get-WindowsServicingInfo -WindowsVersion "1809" | Format-Table

    WindowsVersion BuildNumber ReleaseDate ServiceChannel                                              UpdateKB 
    -------------- ----------- ----------- --------------                                              --------
    1809           17763.503   05/14/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4494441
    1809           17763.475   05/03/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4495667
    1809           17763.439   05/01/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4501835
    1809           17763.437   04/09/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4493509
    1809           17763.404   04/02/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4490481
    1809           17763.379   03/12/2019  {Semi-Annual Channel, Semi-Annual Channel (Targeted), LTSC} KB4489899
    1809           17763.348   03/01/2019  {Semi-Annual Channel (Targeted), LTSC}                      KB4482887
    [...]
#>
function Get-WindowsServicingInfo {
    [CmdletBinding()]
    param(
        [ValidateSet("Semi-Annual Channel", "LTSB/LTSC")][Parameter(ParameterSetName = "ServiceChannel")][string]$ServicingChannel,
        [ValidateNotNullOrEmpty()][Parameter(ParameterSetName = "VersionNumber")][string]$WindowsVersion
    )
    
    begin {
        function ConvertToDate {
            param([Parameter(ValueFromPipeline)][string]$Input)
    
            if ($Input -eq "End of service") {
                return "End of Life"
            }
            else {
                return [convert]::ToDateTime($Input).ToString("MM/dd/yyyy")
            }
        }
    
        $Windows10VersionPage = Invoke-WebRequest -Uri "https://winreleaseinfoprod.blob.core.windows.net/winreleaseinfoprod/en-US.html"
    
        switch ($PSCmdlet.ParameterSetName) {
            "ServiceChannel" {
                switch ($ServicingChannel) {
    
                    "Semi-Annual Channel" {
                        $TableRegex = "<span>Semi-Annual Channel<\/span>\p{Zs}*<br><br>\p{Zs}*<table .*?>.*?<tr>.*?<\/tr>\s*((?s).*?)<\/table>"
                    }
    
                    "LTSB/LTSC" {
                        $TableRegex = "<span>Enterprise and IoT Enterprise LTSB/LTSC editions<\/span>\p{Zs}*<br><br>\p{Zs}*<table .*?>.*?<tr>.*?<\/tr>\s*((?s).*?)<\/table>" 
                    }
                }
                $VersionInfoRegex = "<tr.*?>\s*<td>(?'windowsVersion'.*?)<\/td>\s*<td.*>(?'serviceChannel'.*?)<\/td>\s*<td>(?'releaseDate'.*?)<\/td>\s*<td>(?'buildNumber'.*?)<\/td>\s*<td>(?'latestRevisionDate'.*?)<\/td>\s*<td>(?'consumerEOL'.*?)<\/td>\s*<td>(?'enterpriseEOL'.*?)<\/td>(?:\s*.*\s*|\s*)<\/tr>"
    
                function ParseData {
                    param($Version)
                    $Groups = $Version.Groups
    
                    $Obj = [pscustomobject] @{
                        "Version"           = ($Groups | Where-Object -Property "Name" -EQ "windowsVersion" | Select-Object -ExpandProperty "Value");
                        "ServiceChannel"    = ($Groups | Where-Object -Property "Name" -EQ "serviceChannel" | Select-Object -ExpandProperty "Value");
                        "ReleaseDate"       = ($Groups | Where-Object -Property "Name" -EQ "releaseDate" | Select-Object -ExpandProperty "Value" | ConvertToDate);
                        "BuildNumber"       = ($Groups | Where-Object -Property "Name" -EQ "buildNumber" | Select-Object -ExpandProperty "Value");
                        "LastRevisionDate"  = ($Groups | Where-Object -Property "Name" -EQ "latestRevisionDate" | Select-Object -ExpandProperty "Value" | ConvertToDate);
                        "ConsumerEolDate"   = ($Groups | Where-Object -Property "Name" -EQ "consumerEOL" | Select-Object -ExpandProperty "Value" | ConvertToDate);
                        "EnterpriseEolDate" = ($Groups | Where-Object -Property "Name" -EQ "enterpriseEOL" | Select-Object -ExpandProperty "Value" | ConvertToDate)
                    }
    
                    $defaultOutput = "Version", "ServiceChannel", "ReleaseDate", "BuildNumber", "LastRevisionDate", "ConsumerEolDate", "EnterpriseEolDate"
                    $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
                    $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)
                    Add-Member -InputObject $Obj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput
    
                    return $Obj
                }
            }
    
            "VersionNumber" {
                $TableRegex = "<h4>.*Version $($WindowsVersion)\s\(OS build \d{5}\).*\n<\/a><\/h4>\s*<table.*>\s*<tr>(?:(?s).*?)<\/tr>\s*((?s).*?)<\/table>"
                $VersionInfoRegex = "<tr>\s*<td>(?'buildNumber'.*?)<\/td>\s*<td>(?'releaseDate'.*?)<\/td>\s*<td>(?'ServiceChannel'.*?)<\/td>\s*<td>(?:<a.*>(?'updateKB'.*?)<\/a>|)<\/td>\s*<\/tr>"
    
                function ParseData {
                    param($Version, $WindowsVersion)
                    $Groups = $Version.Groups
    
                    $KbUpdate = $Groups | Where-Object -Property "Name" -EQ "updateKB" | Select-Object -ExpandProperty "Value"
                    if ($KbUpdate) {
                        $KbUpdate = ($KbUpdate -replace " ", "")
                    }
                    else {
                        $KbUpdate = "N/A"
                    }
    
                    $Obj = New-Object -TypeName pscustomobject -Property @{
                        "Version"        = $WindowsVersion
                        "BuildNumber"    = ($Groups | Where-Object -Property "Name" -EQ "buildNumber" | Select-Object -ExpandProperty "Value");
                        "ReleaseDate"    = ($Groups | Where-Object -Property "Name" -EQ "releaseDate" | Select-Object -ExpandProperty "Value" | ConvertToDate);
                        "ServiceChannel" = (($Groups | Where-Object -Property "Name" -EQ "ServiceChannel" | Select-Object -ExpandProperty "Value") -replace " <span> &bull; </span> ", "," -split ",");
                        "UpdateKB"       = $KbUpdate
                    }
    
                    $defaultOutput = "Version", "BuildNumber", "ReleaseDate", "ServiceChannel", "UpdateKB"
                    $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
                    $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)
                    Add-Member -InputObject $Obj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput
    
                    return $Obj
                }
            }
        }
    
        $Table = ([regex]::Match($Windows10VersionPage.Content, $TableRegex)).Groups[1].Value
    
        $VersionInfo = [regex]::Matches($Table, $VersionInfoRegex)
    }
    
    process {
        $ReturnData = foreach ($Version in $VersionInfo) {
            switch ($PSCmdlet.ParameterSetName) {
                "ServiceChannel" {
                    $ParseDataSplat = @{
                        "Version" = $Version
                    }
                }
                "VersionNumber" {
                    $ParseDataSplat = @{
                        "Version"        = $Version;
                        "WindowsVersion" = $WindowsVersion
                    }
                }
            }
            ParseData @ParseDataSplat
        }
    }
    
    end {
        return $ReturnData
    }    
}