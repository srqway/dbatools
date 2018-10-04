﻿function Get-DbaDbFeatureUsage {
    <#
        .SYNOPSIS
            Shows features that are enabled in the database but not supported on the all the editions of SQL Server.

        .DESCRIPTION
            Shows features that are enabled in the database but not supported on the all the editions of SQL Server.

            This feature must be removed before the database can be migrated to all available editions of SQL Server.

        .PARAMETER SqlInstance
            The target SQL Server instance

        .PARAMETER SqlCredential
            Login to the target instance using alternate Windows or SQL Login Authentication. Accepts credential objects (Get-Credential).

        .PARAMETER Database
            The database(s) to process - this list is auto-populated from the server. If unspecified, all databases will be processed.

        .PARAMETER ExcludeDatabase
            The database(s) to exclude - this list is auto-populated from the server

        .PARAMETER InputObject
            A collection of databases (such as returned by Get-DbaDatabase), to be tested.

        .PARAMETER EnableException
            By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
            This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
            Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

        .NOTES
            Author: Brandon Abshire, netnerds.net
            Tags: Deprecated
            Website: https://dbatools.io
            Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
-           License: MIT https://opensource.org/licenses/MIT

        .LINK
            https://dbatools.io/Get-DbaDbFeatureUsage

        .EXAMPLE
            C:\> Get-DbaDatabase -SqlInstance sql2008 -Database testdb, db2 | Get-DbaDbFeatureUsage

            Shows features that are enabled in the testdb and db2 databases but
            not supported on the all the editions of SQL Server.
    #>
    [CmdletBinding()]
    Param (
        [Alias("ServerInstance", "SqlServer", "SqlServers")]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string[]]$Database,
        [string[]]$ExcludeDatabase,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )

    begin {
        $sql = "SELECT  SERVERPROPERTY('MachineName') AS ComputerName,
            ISNULL(SERVERPROPERTY('InstanceName'), 'MSSQLSERVER') AS InstanceName,
            SERVERPROPERTY('ServerName') AS SqlInstance, DB_NAME() as [Database], feature_id as Id,
            feature_name as Feature FROM sys.dm_db_persisted_sku_features"
    }

    process {
        foreach ($instance in $SqlInstance) {
            $InputObject += Get-DbaDatabase -SqlInstance $instance -SqlCredential $SqlCredential -Database $Database -ExcludeDatabase $ExcludeDatabase
        }
        foreach ($db in $InputObject) {
            Write-Message -Level Verbose -Message "Processing $db on $($db.Parent.Name)"

            if ($db.IsAccessible -eq $false) {
                Stop-Function -Message "The database $db is not accessible. Skipping database." -Continue
            }

            try {
                $db.Query($sql)
            }
            catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}