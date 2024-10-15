codeunit 10675 "SAF-T Export Mgt."
{
    TableNo = "SAF-T Export Header";

    trigger OnRun()
    begin
        StartExport(Rec);
    end;

    var
        ExportIsInProgressMsg: Label 'The export is in progress. Starting a new job cancels the current progress.\';
        CancelExportIsInProgressQst: Label 'Do you want to cancel all export jobs and restart?';
        DeleteExportIsInProgressQst: Label 'Do you want to delete the export entry?';
        RestartExportLineQst: Label 'Do you want to restart the export for this line?';
        ExportIsCompletedQst: Label 'The export was completed. You can download the export result choosing the Download SAF-T File action.\';
        RestartExportQst: Label 'Do you want to restart the export to get a new SAF-T file?';
        SetStartDateTimeAsCurrentQst: Label 'The Earliest Start Date/Time field is not filled in. Do you want to proceed and start the export immediately?';
        SAFTExportTxt: Label 'SAF-T Export';
        StartingExportTxt: Label 'Starting SAF-T export with ID: %1, Parallel: %2, Split By Month: %3', Comment = '%1 - integer; %2,%3 - boolean';
        CancellingExportTxt: Label 'Cancelling SAF-T Export with ID: %1, Task ID: %2', Comment = '%1 - integer; %2 - GUID';
        NotPossibleToScheduleMsg: Label 'You are not allowed to schedule the SAF-T file generation';
        GenerateSAFTFileImmediatelyQst: Label 'Since you did not schedule the SAF-T file generation, it will be generated immediately which can take a while. Do you want to continue?';
        NoErrorMessageErr: Label 'The generation of a SAF-T file failed but no error message was logged.';
        FilesExistsInFolderErr: Label 'One or more files exist in the folder that you want to export the SAF-T file to. Specify a folder with no files in it.';
        SAFTFileGeneratedTxt: Label 'SAF-T file generated.';
        SAFTFileNotGeneratedTxt: Label 'SAF-T file generated.';
        ParallelSAFTFileGenerationTxt: Label 'Parallel SAF-T file generation';
        ZipArchiveFilterTxt: Label 'Zip File (*.zip)|*.zip', Locked = true;
        SAFTZipFileTxt: Label 'SAF-T Financial.zip', Locked = true;
        ZipArchiveSaveDialogTxt: Label 'Export SAF-T archive';
        MasterDataMsg: Label 'MasterData';
        GLEntriesMsg: Label 'General ledger entries from %1 to %2';
        NoZipFileGeneratedErr: Label 'No zip file generated.';
        NoOfJobsInProgressTxt: Label 'No of jobs in progress: %1', Comment = '%1 = number';
        JobsStartedOrFailedTxt: Label 'There are %1 jobs not started or failed', Comment = '%1 = number';
        SessionLostTxt: Label 'The task for line %1 was lost.', Comment = '%1 = number';
        NotPossibleToScheduleTxt: Label 'It is not possible to schedule the task for line %1 because the Max. No. of Jobs field contains %2.', Comment = '%1,%2 = numbers';
        ScheduleTaskForLineTxt: Label 'Schedule a task for line %1.', Comment = '%1';

    local procedure StartExport(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        DummyTempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileOutstream: OutStream;
    begin
        if not PrepareForExport(SAFTExportHeader) then
            exit;

        SendTraceTagOfExport(SAFTExportTxt, GetStartTraceTagMessage(SAFTExportHeader));
        CreateExportLines(SAFTExportHeader);

        SAFTExportHeader.validate(Status, SAFTExportHeader.Status::"In Progress");
        SAFTExportHeader.Validate("Execution Start Date/Time", CurrentDateTime());
        SAFTExportHeader.Validate("Execution End Date/Time", 0DT);
        DummyTempBlob.CreateInStream(FileInStream);
        SAFTExportHeader."SAF-T File".CreateOutStream(FileOutstream);
        CopyStream(FileOutstream, FileInStream);
        SAFTExportHeader.Modify(true);
        Commit();

        StartExportLines(SAFTExportHeader);
        SAFTExportHeader.Find();
    end;

    procedure DeleteExport(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
    begin
        if not CheckStatus(SAFTExportHeader.Status, DeleteExportIsInProgressQst) then
            exit;
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::"In Progress");
        if SAFTExportLine.FindSet() then
            repeat
                CancelTask(SAFTExportLine);
            until SAFTExportLine.Next() = 0;
        SAFTExportLine.SetRange(Status);
        SAFTExportLine.DeleteAll(true);
    end;

    procedure ThrowNoParallelExecutionNotification()
    var
        ParallelExecutionNotification: Notification;
    begin
        ParallelExecutionNotification.Message := NotPossibleToScheduleMsg;
        ParallelExecutionNotification.Scope := NotificationScope::LocalScope;
        ParallelExecutionNotification.Send();
    end;

    procedure RestartTaskOnExportLine(var SAFTExportLine: Record "SAF-T Export Line")
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        DummyNoOfJobs: Integer;
        NotBefore: DateTime;
    begin
        if not CheckStatus(SAFTExportLine.Status, RestartExportLineQst) then
            exit;
        CancelTask(SAFTExportLine);
        SAFTExportHeader.Get(SAFTExportLine.ID);
        NotBefore := CurrentDateTime();
        RunGenerateSAFTFileOnSingleLine(SAFTExportLine, DummyNoOfJobs, NotBefore, SAFTExportHeader);
    end;

    procedure SendTraceTagOfExport(Category: Text; TraceTagMessage: Text)
    begin
        SendTraceTag('0000A4J', Category, Verbosity::Normal, TraceTagMessage, DataClassification::SystemMetadata);
    end;

    procedure UpdateExportStatus(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TotalCount: Integer;
        Status: Integer;
    begin
        if SAFTExportHeader.ID = 0 then
            exit;

        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        TotalCount := SAFTExportLine.Count();
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        IF SAFTExportLine.Count() = TotalCount then begin
            SAFTExportHeader.Validate(Status, SAFTExportHeader.Status::Completed);
            SAFTExportHeader.Validate("Execution End Date/Time", CurrentDateTime());
            SAFTExportHeader.Modify(true);
            exit;
        end;

        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Failed);
        if SAFTExportLine.IsEmpty() then
            Status := SAFTExportHeader.Status::"In Progress"
        else
            Status := SAFTExportHeader.Status::Failed;

        SAFTExportHeader.Validate(Status, Status);
        SAFTExportHeader.Modify(true);
    end;

    procedure StartExportLinesNotStartedYet(SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
        NoOfJobs: Integer;
        NotBefore: DateTime;
        RunThisLine: Boolean;
    begin
        if not SAFTExportHeader."Parallel Processing" then
            exit;

        NoOfJobs := GetNoOfJobsInProgress();
        LogState(SAFTExportLine, StrSubstNo(NoOfJobsInProgressTxt, NoOfJobs), false);
        if NoOfJobs > SAFTExportHeader."Max No. Of Jobs" then
            exit;

        SAFTExportLine.LockTable();
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.SetFilter("No. Of Retries", '<>%1', 0);
        SAFTExportLine.SetFilter(Status, '<>%1', SAFTExportLine.Status::Completed);
        LogState(SAFTExportLine, StrSubstNo(JobsStartedOrFailedTxt, SAFTExportLine.Count()), false);
        if not SAFTExportLine.FindSet() then
            exit;

        NotBefore := CurrentDateTime();
        repeat
            RunThisLine := false;
            if SAFTExportLine.Status = SAFTExportLine.Status::"In Progress" then begin
                RunThisLine := not IsSessionActive(SAFTExportLine);
                if RunThisLine then
                    LogState(SAFTExportLine, StrSubstNo(SessionLostTxt, SAFTExportLine."Line No."), true);
            end else
                RunThisLine := true;
            If RunThisLine then
                RunGenerateSAFTFileOnSingleLine(SAFTExportLine, NoOfJobs, NotBefore, SAFTExportHeader);
        until SAFTExportLine.Next() = 0;
    end;

    procedure ShowActivityLog(SAFTExportLine: Record "SAF-T Export Line")
    var
        ActivityLog: Record "Activity Log";
        ActivityLogPage: Page "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", SAFTExportLine.RecordId());
        ActivityLogPage.SetTableView(ActivityLog);
        ActivityLogPage.Run();
    end;

    procedure ShowErrorOnExportLine(SAFTExportLine: Record "SAF-T Export Line")
    var
        ActivityLog: Record "Activity Log";
        Stream: InStream;
        ErrorMessage: Text;
    begin
        with ActivityLog do begin
            SetRange("Record ID", SAFTExportLine.RecordId());
            if not FindLast() or (Status <> Status::Failed) then
                exit;
            CalcFields("Detailed Info");
            if not "Detailed Info".HasValue() then
                error(NoErrorMessageErr);
            "Detailed Info".CreateInStream(Stream);
            Stream.ReadText(ErrorMessage);
            if ErrorMessage = '' then
                error(NoErrorMessageErr);
            Message(ErrorMessage);
        end;
    end;

    procedure LogSuccess(SAFTExportLine: Record "SAF-T Export Line")
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(SAFTExportLine.RecordId(), ActivityLog.Status::Success, '', SAFTFileGeneratedTxt, '');
        SendTraceTagOfExport(SAFTExportTxt, SAFTFileGeneratedTxt);
    end;

    procedure LogError(SAFTExportLine: Record "SAF-T Export Line")
    var
        ActivityLog: Record "Activity Log";
        ErrorMessage: Text;
    begin
        ErrorMessage := GetLastErrorText();
        ActivityLog.LogActivity(SAFTExportLine.RecordId(), ActivityLog.Status::Failed, '', SAFTFileNotGeneratedTxt, ErrorMessage);
        ActivityLog.SetDetailedInfoFromText(ErrorMessage);
    end;

    local procedure LogState(SAFTExportLine: Record "SAF-T Export Line"; Description: Text[250]; SetTraceTag: Boolean)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(SAFTExportLine.RecordId(), ActivityLog.Status::Success, '', ParallelSAFTFileGenerationTxt, Description);
        SendTraceTagOfExport(ParallelSAFTFileGenerationTxt, Description);
    end;

    local procedure StartExportLines(SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
        NoOfJobs: Integer;
        NotBefore: DateTime;
    begin
        SAFTExportLine.LockTable();
        SAFTExportLine.SetRange(Id, SAFTExportHeader.ID);
        SAFTExportLine.FindSet();
        NoOfJobs := 1;
        NotBefore := SAFTExportHeader."Earliest Start Date/Time";
        repeat
            RunGenerateSAFTFileOnSingleLine(SAFTExportLine, NoOfJobs, NotBefore, SAFTExportHeader);
        until SAFTExportLine.Next() = 0;
    end;

    local procedure RunGenerateSAFTFileOnSingleLine(var SAFTExportLine: Record "SAF-T Export Line"; var NoOfJobs: Integer; var NotBefore: DateTime; SAFTExportHeader: Record "SAF-T Export Header")
    var
        DoNotScheduleTask: Boolean;
        TaskID: Guid;
    begin
        if SAFTExportHeader."Parallel Processing" and (NoOfJobs > SAFTExportHeader."Max No. Of Jobs") then begin
            LogState(
                SAFTExportLine, StrSubstNo(NotPossibleToScheduleTxt, SAFTExportLine."Line No.", NoOfJobs), false);
            exit;
        end;

        SAFTExportLine.Validate(Status, SAFTExportLine.Status::"In Progress");
        SAFTExportLine.Validate(Progress, 0);
        if SAFTExportHeader."Parallel Processing" then begin
            LogState(SAFTExportLine, StrSubstNo(ScheduleTaskForLineTxt, SAFTExportLine."Line No."), true);
            NotBefore += 3000; // have a delay between running jobs to avoid deadlocks
            OnBeforeScheduleTask(DoNotScheduleTask, TaskID);
            if DoNotScheduleTask then
                SAFTExportLine."Task ID" := TaskID
            else
                SAFTExportLine."Task ID" :=
                    TaskScheduler.CreateTask(
                        codeunit::"Generate SAF-T File", Codeunit::"SAF-T Export Error Handler", true, CompanyName(),
                        NotBefore, SAFTExportLine.RecordId());
            SAFTExportLine.Modify(true);
            Commit();
            NoOfJobs += 1;
            exit;
        end;
        SAFTExportLine."Task ID" := CreateGuid();
        SAFTExportLine.Modify(true);
        Commit();

        ClearLastError();
        if not codeunit.Run(codeunit::"Generate SAF-T File", SAFTExportLine) then
            codeunit.Run(codeunit::"SAF-T Export Error Handler", SAFTExportLine);
        Commit();
    end;

    local procedure PrepareForExport(var SAFTExportHeader: Record "SAF-T Export Header"): Boolean
    var
        SAFTExportCheck: Codeunit "SAF-T Export Check";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageManagement: Codeunit "Error Message Management";
    begin
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        SAFTExportCheck.Run(SAFTExportHeader);
        if ErrorMessageManagement.GetLastErrorID() <> 0 then begin
            ErrorMessageHandler.ShowErrors();
            exit(false);
        end;

        if SAFTExportHeader.Status = SAFTExportHeader.Status::"In Progress" then
            if HandleConfirm(StrSubstNo('%1%2', ExportIsInProgressMsg, CancelExportIsInProgressQst)) then
                RemoveExportLines(SAFTExportHeader)
            else
                exit(false);
        if SAFTExportHeader.Status = SAFTExportHeader.Status::Completed then
            if not HandleConfirm(StrSubstNo('%1%2', ExportIsCompletedQst, RestartExportQst)) then
                exit(false);

        if (SAFTExportHeader."Parallel Processing") and (SAFTExportHeader."Earliest Start Date/Time" = 0DT) then begin
            if not HandleConfirm(SetStartDateTimeAsCurrentQst) then
                exit(false);
            SAFTExportHeader."Earliest Start Date/Time" := CurrentDateTime();
        end;
        if not SAFTExportHeader."Parallel Processing" then
            if not HandleConfirm(GenerateSAFTFileImmediatelyQst) then
                exit(false);
        exit(true)
    end;

    local procedure CreateExportLines(SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
        GLEntry: Record "G/L Entry";
        StartingDate: Date;
        EndingDate: Date;
        StopExportEntriesByPeriod: Boolean;
        LineNo: Integer;
    begin
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.DeleteAll(true);

        // Master data
        InsertSAFTExportLine(SAFTExportLine, LineNo, SAFTExportHeader, true, MasterDataMsg, SAFTExportHeader."Starting Date", SAFTExportHeader."Ending Date");
        if not SAFTExportHeader."Split By Month" then begin
            // General ledger entries
            InsertSAFTExportLine(
                SAFTExportLine, LineNo, SAFTExportHeader, false,
                StrSubstNo(GLEntriesMsg, SAFTExportHeader."Starting Date", SAFTExportHeader."Ending Date"),
                SAFTExportHeader."Starting Date", SAFTExportHeader."Ending Date");
            exit;
        end;

        StartingDate := SAFTExportHeader."Starting Date";
        EndingDate := CalcDate('<CM>', SAFTExportHeader."Starting Date");
        repeat
            StopExportEntriesByPeriod := EndingDate >= SAFTExportHeader."Ending Date";
            if CalcDate('<CM>', EndingDate) >= SAFTExportHeader."Ending Date" then
                EndingDate := ClosingDate(EndingDate);

            GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
            if not GLEntry.IsEmpty() then
                InsertSAFTExportLine(
                    SAFTExportLine, LineNo, SAFTExportHeader, false,
                    StrSubstNo(GLEntriesMsg, StartingDate, EndingDate), StartingDate, EndingDate);
            StartingDate := normaldate(EndingDate) + 1;
            EndingDate := CalcDate('<CM>', StartingDate);
        until StopExportEntriesByPeriod;
    end;

    local procedure InsertSAFTExportLine(var SAFTExportLine: Record "SAF-T Export Line"; var LineNo: Integer; SAFTExportHeader: Record "SAF-T Export Header"; MasterData: Boolean; Description: Text; StartingDate: Date; EndingDate: Date)
    begin
        SAFTExportLine.Init();
        SAFTExportLine.Validate(ID, SAFTExportHeader.ID);
        LineNo += 1;
        SAFTExportLine.Validate("Line No.", LineNo);
        SAFTExportLine.Validate("Master Data", MasterData);
        SAFTExportLine.Validate(Description, CopyStr(Description, 1, MaxStrLen(Description)));
        SAFTExportLine.Validate("Starting Date", StartingDate);
        SAFTExportLine.Validate("Ending Date", EndingDate);
        SAFTExportLine.Insert(true);
    end;

    local procedure GetStartTraceTagMessage(SAFTExportHeader: Record "SAF-T Export Header"): Text
    begin
        exit(StrSubstNo(StartingExportTxt, SAFTExportHeader.ID, SAFTExportHeader."Parallel Processing", SAFTExportHeader."Split By Month"));
    end;

    local procedure GetCancelTraceTagMessage(SAFTExportLine: Record "SAF-T Export Line"): Text
    begin
        exit(StrSubstNo(CancellingExportTxt, SAFTExportLine.ID, SAFTExportLine."Task ID"));
    end;

    local procedure RemoveExportLines(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTExportLine: Record "SAF-T Export Line";
    begin
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        if not SAFTExportLine.FindSet() then
            exit;

        repeat
            RemoveExportLine(SAFTExportLine);
        until SAFTExportLine.Next() = 0;
    end;

    local procedure RemoveExportLine(var SAFTExportLine: Record "SAF-T Export Line")
    begin
        CancelTask(SAFTExportLine);
        SAFTExportLine.Delete(true);
        SendTraceTagOfExport(SAFTExportTxt, GetCancelTraceTagMessage(SAFTExportLine));
    end;

    local procedure CancelTask(SAFTExportLine: Record "SAF-T Export Line")
    var
        DoNotCancelTask: Boolean;
    begin
        if IsNullGuid(SAFTExportLine."Task ID") then
            exit;

        OnBeforeCancelTask(DoNotCancelTask);
        if not DoNotCancelTask then
            if TaskScheduler.TaskExists(SAFTExportLine."Task ID") then
                TaskScheduler.CancelTask(SAFTExportLine."Task ID");
        SendTraceTagOfExport(SAFTExportTxt, GetCancelTraceTagMessage(SAFTExportLine));
    end;

    procedure BuildZipFilesWithAllRelatedXmlFiles(SAFTExportHeader: Record "SAF-T Export Header")
    var
        CompanyInformation: Record "Company Information";
        SAFTExportLine: Record "SAF-T Export Line";
        FileMgt: Codeunit "File Management";
        SAFTXMLHelper: Codeunit "SAF-T XML Helper";
        ServerDestinationFolder: Text;
        TotalNumberOfFiles: Integer;
    begin
        CompanyInformation.Get();
        ServerDestinationFolder := FileMgt.ServerCreateTempSubDirectory();
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.FindSet();
        TotalNumberOfFiles := SAFTExportLine.Count();
        repeat
            SAFTXMLHelper.ExportSAFTExportLineBlobToFile(
                SAFTExportLine,
                SAFTXMLHelper.GetFilePath(
                    ServerDestinationFolder, CompanyInformation."VAT Registration No.", SAFTExportLine."Created Date/Time",
                    SAFTExportLine."Line No.", TotalNumberOfFiles));
        until SAFTExportLine.Next() = 0;
        ZipMultipleXMLFilesInServerFolder(SAFTExportHeader, ServerDestinationFolder);
    end;

    procedure GenerateZipFileFromSavedFiles(SAFTExportHeader: Record "SAF-T Export Header")
    begin
        if not SAFTExportHeader.AllowedToExportIntoFolder() then
            exit;

        SaveZipOfMultipleXMLFiles(SAFTExportHeader);
    end;

    procedure DownloadZipFileFromExportHeader(SAFTExportHeader: Record "SAF-T Export Header")
    var
        ZipFileInStream: InStream;
        FileName: Text;
    begin
        SAFTExportHeader.CalcFields("SAF-T File");
        if not SAFTExportHeader."SAF-T File".HasValue() then
            error(NoZipFileGeneratedErr);
        SAFTExportHeader."SAF-T File".CreateInStream(ZipFileInStream);
        FileName := SAFTZipFileTxt;
        DownloadFromStream(ZipFileInStream, ZipArchiveSaveDialogTxt, '', ZipArchiveFilterTxt, FileName);
    end;

    procedure ZipMultipleXMLFilesInServerFolder(var SAFTExportHeader: Record "SAF-T Export Header"; ServerDestinationFolder: Text)
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileMgt: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        EntryTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        EntryFileInStream: InStream;
        ZipOutStream: OutStream;
        ZipInStream: InStream;
    begin
        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, ServerDestinationFolder);
        DataCompression.CreateZipArchive();
        TempNameValueBuffer.FindSet();
        repeat
            FileMgt.BLOBImportFromServerFile(EntryTempBlob, TempNameValueBuffer.Name);
            EntryTempBlob.CreateInStream(EntryFileInStream);
            DataCompression.AddEntry(EntryFileInStream, FileMgt.GetFileName(TempNameValueBuffer.Name));
        until TempNameValueBuffer.Next() = 0;
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();

        ZipTempBlob.CreateInStream(ZipInStream);
        SAFTExportHeader."SAF-T File".CreateOutStream(ZipOutStream);
        CopyStream(ZipOutStream, ZipInStream);
        SAFTExportHeader.Modify(true);

        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, ServerDestinationFolder);
        repeat
            FileMgt.DeleteServerFile(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next() = 0;
    end;

    local procedure SaveZipOfMultipleXMLFiles(SAFTExportHeader: Record "SAF-T Export Header")
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileMgt: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        EntryTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        EntryFileInStream: InStream;
        ZipClientFile: File;
        ZipOutStream: OutStream;
        ZipInStream: InStream;
    begin
        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, SAFTExportHeader."Folder Path");
        DataCompression.CreateZipArchive();
        TempNameValueBuffer.FindSet();
        repeat
            FileMgt.BLOBImportFromServerFile(EntryTempBlob, TempNameValueBuffer.Name);
            EntryTempBlob.CreateInStream(EntryFileInStream);
            DataCompression.AddEntry(EntryFileInStream, FileMgt.GetFileName(TempNameValueBuffer.Name));
        until TempNameValueBuffer.Next() = 0;
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();

        ZipTempBlob.CreateInStream(ZipInStream);
        ZipClientFile.Create(SAFTExportHeader."Folder Path" + '\' + SAFTZipFileTxt);
        ZipClientFile.CreateOutStream(ZipOutStream);
        CopyStream(ZipOutStream, ZipInStream);
        ZipClientFile.Close();
    end;

    procedure CheckNoFilesInFolder(SAFTExportHeader: Record "SAF-T Export Header")
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileMgt: Codeunit "File Management";
        ErrorMessageManagement: Codeunit "Error Message Management";
    begin
        if not SAFTExportHeader.AllowedToExportIntoFolder() then
            exit;

        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, SAFTExportHeader."Folder Path");
        if TempNameValueBuffer.Count() <> 0 then
            ErrorMessageManagement.LogError(SAFTExportHeader, FilesExistsInFolderErr, '');
    end;

    procedure SaveXMLDocToFolder(SAFTExportHeader: Record "SAF-T Export Header"; XMLDoc: XmlDocument; FileNumber: Integer): Boolean
    var
        SAFTExportLine: Record "SAF-T Export Line";
        CompanyInformation: Record "Company Information";
        SAFTXMLHelper: Codeunit "SAF-T XML Helper";
        File: File;
        Stream: OutStream;
        FilePath: Text;
        TotalNumberOfFiles: Integer;
    begin
        if not SAFTExportHeader.AllowedToExportIntoFolder() then
            exit(false);
        TotalNumberOfFiles := SAFTExportLine.Count();
        FilePath :=
            SAFTXMLHelper.GetFilePath(
                SAFTExportHeader."Folder Path", CompanyInformation."VAT Registration No.", SAFTExportLine."Created Date/Time", FileNumber, TotalNumberOfFiles);
        File.Create(FilePath);
        File.CreateOutStream(Stream);
        XmlDoc.WriteTo(Stream);
        File.Close();
    end;

    procedure GetAmountInfoFromGLEntry(var AmountXMLNode: Text; var Amount: Decimal; GLEntry: Record "G/L Entry")
    begin
        if GLEntry."Debit Amount" = 0 then begin
            AmountXMLNode := 'CreditAmount';
            Amount := GLEntry."Credit Amount";
        end else begin
            AmountXMLNode := 'DebitAmount';
            Amount := GLEntry."Debit Amount";
        end;
    end;

    procedure GetNotApplicationVATCode(): Code[10]
    var
        SAFTSetup: Record "SAF-T Setup";
    begin
        SAFTSetup.Get();
        exit(SAFTSetup."Not Applicable VAT Code");
    end;

    procedure GetISOCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            exit(GeneralLedgerSetup."LCY Code");
        end;
        Currency.Get(CurrencyCode);
        exit(Currency."ISO Code");
    end;

    local procedure IsSessionActive(SAFTExportLine: Record "SAF-T Export Line"): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        if SAFTExportLine."Server Instance ID" = ServiceInstanceId() then
            exit(ActiveSession.Get(SAFTExportLine."Server Instance ID", SAFTExportLine."Session ID"));
        if SAFTExportLine."Server Instance ID" <= 0 then
            exit(false);
        exit(not IsSessionLoggedOff(SAFTExportLine));
    end;

    local procedure IsSessionLoggedOff(SAFTExportLine: Record "SAF-T Export Line"): Boolean
    var
        SessionEvent: Record "Session Event";
        SAFTExportHeader: Record "SAF-T Export Header";
    begin
        SessionEvent.SetRange("Server Instance ID", SAFTExportLine."Server Instance ID");
        SessionEvent.SetRange("Session ID", SAFTExportLine."Session ID");
        SessionEvent.SetRange("Event Type", SessionEvent."Event Type"::Logoff);
        SAFTExportHeader.Get(SAFTExportLine.Id);
        SessionEvent.SetFilter("Event Datetime", '>%1', SAFTExportHeader."Earliest Start Date/Time");
        SessionEvent.SetRange("User SID", UserSecurityId());
        exit(not SessionEvent.IsEmpty());
    end;

    local procedure GetNoOfJobsInProgress(): Integer
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        ScheduledTask.SetRange("Run Codeunit", Codeunit::"Generate SAF-T File");
        exit(ScheduledTask.Count());
    end;

    local procedure HandleConfirm(ConfirmText: Text): Boolean
    begin
        if not GuiAllowed() then
            exit(true);
        exit(Confirm(ConfirmText, false));
    end;

    local procedure CheckStatus(Status: Option; Question: Text): Boolean
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        StatusMessage: Text;
    begin
        if Status = SAFTExportHeader.Status::"In Progress" then
            StatusMessage := ExportIsInProgressMsg;
        if Status = SAFTExportHeader.Status::Completed then
            StatusMessage := ExportIsCompletedQst;
        if StatusMessage <> '' then
            exit(not HandleConfirm(StatusMessage + Question));
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleTask(var DoNotScheduleTask: Boolean; var TaskID: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCancelTask(var DoNotCancelTask: Boolean)
    begin
    end;
}