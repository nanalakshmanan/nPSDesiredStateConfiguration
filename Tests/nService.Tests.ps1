﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe -Name 'nService.TestTargetResource' -Tags 'UnitTests' -Fixture {
   
    BeforeAll {Set-Service 'w3svc' -StartupType Manual}
    AfterAll  {Set-Service 'w3svc' -StartupType Manual}

    It 'Tests w3svc service as running' {
        $Name = 'w3svc'
        Start-Service $Name
        Test-TargetResource -Name $name -State 'Running' | Should Be $true
    }

    $TestCases = @(
        @{Name = 'w3svc'; State = 'Running'; CompareState = 'Running'; ExpectedResult = $true},
        @{Name = 'w3svc'; State = 'Running'; CompareState = 'Stopped'; ExpectedResult = $false},
        @{Name = 'w3svc'; State = 'Stopped'; CompareState = 'Running'; ExpectedResult = $false},
        @{Name = 'w3svc'; State = 'Stopped'; CompareState = 'Stopped'; ExpectedResult = $true}
    )

    It 'Tests if service <Name> is in state <CompareState> when actual state is <State>' -TestCases $TestCases {
        param($Name, $State, $CompareState, $ExpectedResult)

        if ($State -eq 'Running')
        {        
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        Test-TargetResource -Name $name -State $CompareState | Should Be $ExpectedResult
    }

    $TestCases = @(
        @{Name = 'w3svc'; State = 'Running'; StartupType = 'Disabled'},
        @{Name = 'w3svc'; State = 'Stopped'; StartupType = 'Automatic'}
    )

    It 'Tests if State is <State> and StartupType is <StartupType>' -TestCases $TestCases {
        param($Name, $State, $StartupType)

        {Test-TargetResource -Name $Name -State $State -StartupType $StartupType} | Should Throw
    }

    $TestCases = @(
        @{Name = 'w3svc'; State = 'Stopped'; ST = 'Disabled';   TestST = 'Disabled'; Expected = $true},
        @{Name = 'w3svc'; State = 'Stopped'; ST = 'Automatic';  TestST = 'Disabled'; Expected = $false},
        @{Name = 'w3svc'; State = 'Stopped'; ST = 'Manual';     TestST = 'Disabled'; Expected = $false},
        @{Name = 'w3svc'; State = 'Running'; ST = 'Manual';     TestST = 'Manual';   Expected = $true},
        @{Name = 'w3svc'; State = 'Running'; ST = 'Manual';     TestST = 'Automatic';Expected = $false},
        @{Name = 'w3svc'; State = 'Running'; ST = 'Automatic';  TestST = 'Manual';   Expected = $false},
        @{Name = 'w3svc'; State = 'Running'; ST = 'Automatic';  TestST = 'Automatic';Expected = $true}
    )

    It 'Tests if TestTargetResource returns <Expected> when StartupType for <Name> is set to <ST> and desired is <TestST>' `
    -TestCases $TestCases {
        param($Name, $State, $ST, $TestST, $Expected)

        Set-Service -Name $Name -StartupType $St 

        if ($State -eq 'Running')
        {
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        Test-TargetResource -Name $Name -State $State -StartupType $TestST | Should Be $Expected
    }

    It 'Test for service that is not available' {

        {Test-TargetResource -Name 'foobar' -State Running -StartupType Automatic} | Should Throw
    }

    It 'Test if Invoke-DscResource returns results as expected' -Pending {
    
    }
}

Describe 'nService.SetTargetResource' -Tags 'UnitTests' {
  
    BeforeAll {Set-Service 'w3svc' -StartupType Manual}
    AfterAll  {Set-Service 'w3svc' -StartupType Manual}

    $TestCases = @(
      @{Name = 'w3svc'; InitialState = 'Running'; FinalState = 'Stopped'},
      @{Name = 'w3svc'; InitialState = 'Stopped'; FinalState = 'Running'}
    )

    It 'Tests if service <Name> is in set to state <FinalState> when it is initially <InitialState>' `
        -TestCases $TestCases {
        param($Name, $InitialState, $FinalState)

        if ($InitialState -eq 'Running')
        {
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        Set-TargetResource -Name $Name -State $FinalState 

        (Get-Service $Name).Status | Should Be $FinalState
    }

    $TestCases = @(
        @{Name = 'w3svc'; State = 'Stopped'; StartupType = 'Disabled';  StartMode = 'Disabled'},
        @{Name = 'w3svc'; State = 'Running'; StartupType = 'Automatic'; StartMode = 'Auto'}
        @{Name = 'w3svc'; State = 'Running'; StartupType = 'Manual';    StartMode = 'Manual'}
    )

    It 'Tests if StartupType for <Name> is set to <StartupType>' -TestCases $TestCases {
        param($Name, $State, $StartupType, $StartMode)

        Set-TargetResource -Name $Name -State $State -StartupType $StartupType

        $Service = Get-WmiObject win32_service -Filter "Name='$Name'"

        $Service.StartMode | Should Be $StartMode
    }
}

Describe 'nService.GetTargetResource' -Tags 'UnitTests' {
    BeforeAll {Set-Service 'w3svc' -StartupType Manual}
    AfterAll  {Set-Service 'w3svc' -StartupType Manual}

    $service = Get-TargetResource -Name 'w3svc' -State Running

    $ExpectedResult = @{Name = 'w3svc'; State = 'Running'; StartupType = 'Manual'}

    $ExpectedResult.Keys | % {
        It "Get-TargetResource: Testing if $($_) is $($ExpectedResult[$_])" {
            $service.$_ | Should Be $ExpectedResult[$_]
        }
    }
}