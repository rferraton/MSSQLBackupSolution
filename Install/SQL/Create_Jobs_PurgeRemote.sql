USE [msdb]
GO

/****** Object:  Job [MSSQLBackupSolution-Purge-Remote-FromCMS]    Script Date: 12/1/2023 4:18:22 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 12/1/2023 4:18:22 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'MSSQLBackupSolution-Purge-Remote-FromCMS', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Purge files (backups and shelllog files) on remotes hosts using CMS and group to target hosts', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge - Backup Full]    Script Date: 12/1/2023 4:18:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge - Backup Full', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -executionpolicy bypass -File "D:\MSSQLBackupSolution\PurgeFilesFromCMS.ps1" -FileType "Full" -CMSSqlInstance "localhost\DBA01" -Group "All" -RemoteBackupDirectory "G$\BACKUPDB" -ExecDirectory "D:\MSSQLBackupSolution" -LogDirectory "D:\MSSQLBackupSolution\Logs" -HoursDelay 168', 
		@flags=32, 
		@proxy_name=N'Proxy_MSSQLBackup_Service'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge - Backup Diff]    Script Date: 12/1/2023 4:18:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge - Backup Diff', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -noprofile -executionpolicy bypass -File "D:\MSSQLBackupSolution\PurgeFilesFromCMS.ps1" -FileType "Diff" -CMSSqlInstance "localhost\DBA01" -Group "All" -RemoteBackupDirectory "G$\BACKUPDB" -ExecDirectory "D:\MSSQLBackupSolution" -LogDirectory "D:\MSSQLBackupSolution\Logs" -HoursDelay 168', 
		@flags=32, 
		@proxy_name=N'Proxy_MSSQLBackup_Service'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge - Backup Log]    Script Date: 12/1/2023 4:18:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge - Backup Log', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -noprofile -executionpolicy bypass -File "D:\MSSQLBackupSolution\PurgeFilesFromCMS.ps1" -FileType "Log" -CMSSqlInstance "localhost\DBA01" -Group "All" -RemoteBackupDirectory "G$\BACKUPDB" -ExecDirectory "D:\MSSQLBackupSolution" -LogDirectory "D:\MSSQLBackupSolution\Logs" -HoursDelay 168', 
		@flags=32, 
		@proxy_name=N'Proxy_MSSQLBackup_Service'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Quotidien - 21h', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20231102, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

