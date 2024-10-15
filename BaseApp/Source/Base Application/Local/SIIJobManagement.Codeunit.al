codeunit 10751 "SII Job Management"
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueManagement: Codeunit "Job Queue Management";
        JobQueueEntryStartedTxt: Label 'The job queue entry for detection of missing SII entries has started.';

    procedure RenewJobQueueEntry(JobType: Option HandlePending,HandleCommError,InitialUpload)
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
    begin
        if JobQueueEntryExists(JobType, TempJobQueueEntry) then
            if not TempJobQueueEntry.Scheduled then
                JobQueueManagement.DeleteJobQueueEntries(TempJobQueueEntry."Object Type to Run", TempJobQueueEntry."Object ID to Run");
        CreateJobQueueEntry(JobType);
    end;

    local procedure JobQueueEntryExists(JobType: Option HandlePending,HandleCommError,InitialUpload; var TempJobQueueEntryFound: Record "Job Queue Entry" temporary): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);

        case JobType of
            JobType::HandlePending:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
            JobType::HandleCommError:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Retry Comm. Error");
            JobType::InitialUpload:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Initial Doc. Upload");
        end;

        if JobQueueEntry.FindFirst() then begin
            TempJobQueueEntryFound.Copy(JobQueueEntry);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CreateJobQueueEntry(JobType: Option HandlePending,HandleCommError,InitialUpload)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;

        case JobType of
            JobType::HandlePending:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Job Upload Pending Docs.";
            JobType::HandleCommError:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Job Retry Comm. Error";
            JobType::InitialUpload:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Initial Doc. Upload";
        end;

        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + PeriodInSeconds(JobType) * 1000;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Validate("Notify On Success", false);
        JobQueueEntry.Modify(true);

        JobQueueManagement.StartInactiveJobQueueEntries(
          JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run");
    end;

    local procedure PeriodInSeconds(JobType: Option HandlePending,HandleCommError,InitialUpload): Integer
    begin
        case JobType of
            JobType::HandlePending:
                exit(5);
            JobType::HandleCommError:
                exit(24 * 3600);
            JobType::InitialUpload:
                exit(5);
        end;
    end;

    procedure CreateAndStartJobQueueEntryForMissingEntryDetection(UpdateFrequency: Option Never,Daily,Weekly)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        if UpdateFrequency = UpdateFrequency::Never then
            exit;

        if JobQueueEntryForMissingEntryDetectionExists(JobQueueEntry) then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + 1000;
        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Recreate Missing Entries";
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        SIIRecreateMissingEntries.SendTraceTagOn(JobQueueEntryStartedTxt);
    end;

    procedure DeleteJobQueueEntriesForMissingEntryDetection()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"SII Recreate Missing Entries");
    end;

    procedure JobQueueEntryForMissingEntryDetectionExists(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Recreate Missing Entries");
        exit(JobQueueEntry.FindFirst())
    end;

    procedure RestartJobQueueEntryForMissingEntryCheck(AutomaticMissingEntryCheck: Option)
    begin
        DeleteJobQueueEntriesForMissingEntryDetection();
        CreateAndStartJobQueueEntryForMissingEntryDetection(AutomaticMissingEntryCheck);
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;
}

