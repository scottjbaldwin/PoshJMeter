<#
#>
function Find-JMeter
{
	[CmdletBinding()]
	Param(
	)
	# First look for an environment variable
	Write-Verbose "Looking for JMeterBinPath environment variable"
	if ($env:JMeterBinPath)
	{
		# test the path
		if (Test-JMeterPath -JMeterPath $env:JMeterBinPath)
		{
			# send the path to the pipeline and exit
			$env:JMeterBinPath
			return
		}
	}
	else
	{
		Write-Verbose "No JMeterBinPath environment variable found"
	}

	Write-Verbose "Attempting to guess the path"

	$pathToTry = @( `
		$env:ProgramFiles, `
		${env:ProgramFiles(x86)}, `
		"C:\")

	if ($env:ChocolateyInstall)
	{
		$chocoJMeterPath = Join-Path $env:ChocolateyInstall "lib\jmeter\tools"
		if (Test-Path $chocoJMeterPath)
		{
			$pathToTry += $chocoJMeterPath
		}
	}
	Write-Verbose ("Trying the following locations {0}" -f ($pathToTry -join ", "))
 
	$apacheDir = Get-ChildItem -Path $pathToTry -Filter "apache-jmeter-*" | Sort-Object LastWriteTime -Descending

	if ($apacheDir.Length -gt 0)
	{
		Write-Verbose ("Found {0} possible JMeter paths" -f $apacheDir.Length)
		foreach ($pathToTest in $apacheDir)
		{
			$binPathToTest = Join-Path $pathToTest.FullName "bin"

			if (Test-JMeterPath -JMeterPath $binPathToTest)
			{
				Write-Verbose "Found Jmeter at $binPathToTest"
				$binPathToTest
				return
			}
		}
	}
}

function Test-JMeterPath
{
	[CmdletBinding()]
	Param(
		[Parameter(Position=1, Mandatory=$True)]
		[string] $JMeterPath
	)
	$jmeterBatFile = "jmeter.bat"
	if (Test-Path $JMeterPath)
	{
		# now validate that we can find jmeter.bat
		$batPath = Join-Path $JMeterPath $jmeterBatFile
		if (Test-Path $batPath)
		{
			# return True on the pipeline
			$True
			return
		}
		else
		{
			Write-Verbose "JMeterBinPath Environment variable found, but could not find jmeter.bat at $JMeterPath"
		}
	}
	else
	{
		Write-Verbose "JMeterBinPath Environment variable found, but is not a valid directory"
	}

	$False
}
