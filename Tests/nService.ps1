$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$here\..\DscResources\Nana_nService\Nana_nService.psm1" -Force

