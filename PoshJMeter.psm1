<#
#>
function Find-JMeterBin
{
	$jmeterBatFile = "jmeter.bat"
	# First look for an environment variable
	if ($env:JMeterBinPath)
	{
		# test the path
		if (Test-Path $env:JMeterBinPath)
		{
			# now validate that we can find jmeter.bat
			$batPath = Join-Path $env:JMeterBinPath $JMeterBatFile
			if (Test-Path $batPath)
			{
				# send the path to the pipeline and exit
				$env:JMeterBinPath
				return
			}
			else
			{
				Throw ("Environment variable set, but no install detected at {0}" -f $env:JMeterBinPath)
			}
		}
	}

}
