$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

. "$here\$sut"

Describe "Test-JMeterPath" {
	Context "When Path not found" {
		Mock Test-Path {return $False}

		$path = "C:\Non Folder"
		$result = Test-JMeterPath($path)

		It "Returns False" {
			$result | Should Be $False
		}
	}
	Context "When Path Found" {
		Mock Test-Path {return $True}

		$path = "C:\Program Files (x86)\apache-jmeter-2.13\bin"
		$result = Test-JMeterPath($path)

		It "Returns true" {
			$result | Should Be $True
		}
	}
}

