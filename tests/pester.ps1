param (
	$Show = "None"
)

Write-Host "Starting Tests" -ForegroundColor Green
if ($env:BUILD_BUILDURI -like "vstfs*")
{
	Write-Host "Installing Pester" -ForegroundColor Cyan
    Install-Module Pester -Force -SkipPublisherCheck
}

Write-Output -Message "Loading constants"
. "$PSScriptRoot\constants.ps1"

Write-Output -Message "Importing Module"

Remove-Module kbupdate -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\kbupdate.psd1"
Import-Module "$PSScriptRoot\..\kbupdate.psm1" -Force

$totalFailed = 0
$totalRun = 0

$testresults = @()
Write-Output -Message "Proceeding with individual tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot\functions" -Recurse -File -Filter "*.Tests.ps1"))
{
	Write-Output -Message "  Executing $($file.Name)"
	$results = Invoke-Pester -Script $file.FullName -PassThru
	foreach ($result in $results)
	{
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
			$name = $_.Name
			$testresults += [pscustomobject]@{
				Describe   = $_.Describe
				Context    = $_.Context
				Name	   = "It $name"
				Result	   = $_.Result
				Message    = $_.FailureMessage
			}
		}
	}
}

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed"
}