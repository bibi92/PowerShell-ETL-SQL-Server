#requires -version 2.0   
##############################################################################
##	This script starts a remote SQL Agent Job and wait for it to complete
##  until a MaximumRuntime is met
##############################################################################
#[CmdletBinding()]
Param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
	[string] $ServerName,
	[parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
	[string] $JobName,
	[int] $MaxRuntimeHours = 24
)

#Setup powershell execution params
$ErrorActionPreference ="Stop" 
$DebugPreference ="Continue" #this shows all debug messges, "SilentlyContinue" will supress

#Setup internal script params
$err=0
$WaitIntervalSeconds = 4;
$CheckIntervalSeconds = 2;

function GetSqlServerObject([string] $Server) {
	[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
	$srv = New-Object Microsoft.SqlServer.Management.Smo.Server("$Server")
    
    #We have the object, but need to confirm we can connect
	if ($srv.Urn -eq $null) {
		Write-Error "ERROR Connecting to SqlServer $Server"
		throw "ERROR Connecting to SqlServer $Server"
	}
	return $srv
}


###############################################################################
########## Main body ##########################################################
Try
{

Write-Debug "ServerName=$ServerName"
Write-Debug "JobName=$JobName"

$SqlServer = GetSqlServerObject $ServerName

$Job = $SqlServer.JobServer.Jobs[$JobName]
echo "initial"
Write-Debug "Job.LastRunDate=$($Job.LastRunDate)"
Write-Debug "Job.LastRunOutcome=$($Job.LastRunOutcome)"
Write-Debug "Job.IsTouched=$($Job.IsTouched)"
Write-Debug "Job.IsObjectDirty=$($Job.IsObjectDirty)"
Write-Debug "Job.State=$($Job.State)"
Write-Debug "Job.CurrentRunStatus=$($Job.CurrentRunStatus)"
$Job.Start();
echo "after start"
Write-Debug "Job.LastRunDate=$($Job.LastRunDate)"
Write-Debug "Job.IsTouched=$($Job.IsTouched)"
Write-Debug "Job.IsObjectDirty=$($Job.IsObjectDirty)"
Write-Debug "Job.State=$($Job.State)"
Write-Debug "Job.CurrentRunStatus=$($Job.CurrentRunStatus)"
$Job.Refresh();
echo "after refresh"
Write-Debug "Job.LastRunDate=$($Job.LastRunDate)"
Write-Debug "Job.IsTouched=$($Job.IsTouched)"
Write-Debug "Job.IsObjectDirty=$($Job.IsObjectDirty)"
Write-Debug "Job.State=$($Job.State)"
Write-Debug "Job.CurrentRunStatus=$($Job.CurrentRunStatus)"


#If already running, exit w/failure




#Wait for SQL Server to start the job
Write-Debug "Begin wait for $WaitIntervalSeconds seconds";
Start-Sleep -Seconds $WaitIntervalSeconds;
$Job.Refresh();

echo "after wait interval & refresh"
Write-Debug "Job.LastRunDate=$($Job.LastRunDate)"
Write-Debug "Job.IsTouched=$($Job.IsTouched)"
Write-Debug "Job.IsObjectDirty=$($Job.IsObjectDirty)"
Write-Debug "Job.State=$($Job.State)"
Write-Debug "Job.CurrentRunStatus=$($Job.CurrentRunStatus)"
$i=0

#Loop while the job runs
while (
    $Job.CurrentRunStatus -ne `
		[Microsoft.SqlServer.Management.Smo.Agent.JobExecutionStatus]::Idle `
	)
{
	Start-Sleep -Seconds $CheckIntervalSeconds;
    $Job.Refresh();
    echo "i=$i"
    echo "after loop interval & refresh"
    Write-Debug "Job.LastRunDate=$($Job.LastRunDate)"
    Write-Debug "Job.IsTouched=$($Job.IsTouched)"
    Write-Debug "Job.IsObjectDirty=$($Job.IsObjectDirty)"
    Write-Debug "Job.State=$($Job.State)"
    Write-Debug "Job.CurrentRunStatus=$($Job.CurrentRunStatus)"
    $i++
};

echo $Job.LastRunDate, $Job.LastRunOutcome



}
Catch [System.Exception] 
{
	$ex = $_.Exception 
	Write-Host $ex.Message 
	$err=1
}
Finally 
{ 
	if (!$err) {
		Write-Host "Success!" 
		exit 0
	} 
	else {
		Write-Error "Failed!"
		exit 1 
	}
}
