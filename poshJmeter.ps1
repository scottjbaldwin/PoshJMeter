<#
.SYNOPSIS

Starts JMeter

.DESCRIPTION

Based on the parameters passed, JMeter is started, either in GUI mode, or non-gui mode.

If JMeter is started in GUI mode, it is launched in a seperate process, and control is returned to the shell.

If JMeter is launched in non-gui mode (using the -NoGui switch), then it is run as part of the current session, and control is only returned to the command line once the test is finished.

.PARAMETER TestFile

The file o open in JMeter.

.PARAMETER Property

The properties to pass to JMeter. NOTE This uses the -JProp=Value command line parameters.

.PARAMETER LogFile

The path to the log file

.PARAMETER NoGui

Specifies that the test should be run in non-gui mode.

.EXAMPLE

PS C:\>Start-JMeter

Starts JMeter GUI with a blank project

.EXAMPLE

PS C:\>Start-JMeter -TestFile c:\tests\MyLoadTest.jmx

Starts the jmeter GUI and opens up the test file at C:\tests\MyLoadTest.jmx. NOTE an exception will be thrown if the test file does not exist.

PS C:\Start-JMeter -TestFile C:\tests\MyLoadTest.jmx -Property @{remote_hosts="10.20.1.88,10.20.1.89"} -NoGui

Runs the test in non gui mode setting the remote_hosts to 10.20.1.88 and 10.20.1.89

#>
function Start-JMeter
{
	[CmdletBinding()]
	Param(
		[Parameter(Position=1)]
		[alias("t")]
		[string]$TestFile,

		[Parameter()]
		[hashtable]$Property,

		[Parameter()]
		[string]$Logfile,

		[Parameter()]
		[alias("n")]
		[switch]$NoGui
	)

	$jmeterBinPath = Find-JMeter

	$jmeterBat = Join-Path $jmeterBinPath "jmeter.bat"
	Write-Verbose "Path to jmeter $jmeterBat"

	$properties = @()
	if ($Property)
	{
		$properties = $Property.Keys | % {"-J{0}={1}" -f $_, $Property[$_] }
	}

	if ($NoGui.IsPresent)
	{
		if (-not $TestFile)
		{
			Throw "You must specify a test file to run with -TestFile"
		}
		if (Test-Path -PathType Leaf $TestFile)
		{
			$cmd = "$jmeterBat -n -t $TestFile -j $LogFile"

			if ($properties.Length -gt 0)
			{
				$cmd += $properties -join " "
			}

			&$cmd
		}
		else
		{
			Throw "You must spicify a valid test file to execute"
		}
	}
	else
	{
		$arguments = $properties
		if ($TestFile)
		{
			if (Test-Path -PathType Leaf $TestFile)
			{
				$arguments += @("-t $TestFile")
			}
			else
			{
				Throw "Specified test file invalid"
			}
		}

		if ($LogFile)
		{
			$arguments += @("-j $LogFile")
		}

		if ($arguments.Length -gt 0)
		{
			Write-Verbose ("Starting jmeter with the following parameters {0}" -f ($arguments -join ", "))
			Start-Process $jmeterBat -ArgumentList $arguments -NoNewWindow
		}
		else
		{
			Start-Process $jmeterBat -NoNewWindow
		}
	}
}
<#
.SYNOPSIS

Finds the jmeter bin folder.

.DESCRIPTION

Searches the most likely locations for the JMeter bin folder. The order of search is

- $env:JMeterBinPath - Environment variable you can set to explicitly use a particular version of JMeter
- One of the following path locations
  * C:\
  * C:\Program Files
  * C:\Program Files (x86)
  * $env:ChocolateyInstall\lib\jmeter\tools

If more than one is found, the most recent of these will be used.

.EXAMPLE

PS C:\>Find-JMeter
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

	Throw "Unable to find JMeter path"
}

<#
.SYNOPSIS

Tests a path to see if it has JMeter.bat

.DESCRIPTION

Validates that JMeter.bat is at the path specified.

.PARAMETER JMeterPath

The suspected JMeter path to validate

.EXAMPLE

PS C:\>Test-JMeterPath "C:\Program Files\apache-jmeter-2.13"

#>
function Test-JMeterPath
{
	[CmdletBinding()]
	Param(
		[Parameter(Position=1, Mandatory=$True)]
		[string] $JMeterPath
	)
	$jmeterBatFile = "jmeter.bat"
	if (Test-Path -PathType Container $JMeterPath)
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
