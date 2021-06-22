codeunit 5371 "CRM Synch. Job Management"
{

    trigger OnRun()
    begin
    end;

    procedure SetInitialState(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        with CRMSynchJobStatusCue do begin
            Reset;
            if not FindFirst then begin
                Init;
                Code := GetDefaultPkValue;
                Insert;
            end;
            SetFilters(CRMSynchJobStatusCue);
        end;
    end;

    procedure OnReset(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        with CRMSynchJobStatusCue do begin
            Reset;
            FindFirst;
            "Reset Date" := GetLastFailedDate(GetDefaultJobRunner);
            Modify;
            SetFilters(CRMSynchJobStatusCue);
        end;
    end;

    local procedure FindLastJobQueue(var JobQueueEntry: Record "Job Queue Entry"; JobToRun: Integer): Boolean
    begin
        with JobQueueEntry do begin
            SetRange(Status, Status::Error);
            SetRange("Object ID to Run", JobToRun);
            exit(FindLast);
        end;
    end;

    local procedure GetLastFailedDate(JobToRun: Integer): DateTime
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if FindLastJobQueue(JobQueueEntry, JobToRun) then
            exit(JobQueueEntry."Last Ready State");
        exit(CreateDateTime(Today, Time));
    end;

    local procedure GetDefaultPkValue(): Code[10]
    begin
        exit('0');
    end;

    local procedure SetFilters(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        with CRMSynchJobStatusCue do begin
            SetRange("Object ID to Run", GetDefaultJobRunner);
            SetFilter("Date Filter", '>%1', "Reset Date");
        end;
    end;

    procedure GetDefaultJobRunner(): Integer
    begin
        exit(CODEUNIT::"Integration Synch. Job Runner");
    end;
}

