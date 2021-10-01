codeunit 449 "Job Queue Start Codeunit"
{
    Permissions = TableData "Job Queue Entry" = rm, tabledata "Report Settings Override" = rim;
    TableNo = "Job Queue Entry";

    var
        JobQueueStartContextTxt: Label 'Job Queue Start', Locked = true;

    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageRegisterId: Guid;
        Success: Boolean;
        LastError: DotNet LastError;
    begin
        if "User Language ID" <> 0 then
            GlobalLanguage("User Language ID");

        ErrorMessageManagement.Activate(ErrorMessageHandler);
        ErrorMessageManagement.PushContext(ErrorContextElement, Rec.RecordId(), 0, JobQueueStartContextTxt);
        case "Object Type to Run" of
            "Object Type to Run"::Codeunit:
                Success := Codeunit.Run("Object ID to Run", Rec);
            "Object Type to Run"::Report:
                Success := RunReport("Object ID to Run", Rec);
        end;

        if (not Success) or ErrorMessageManagement.GetErrorsInContext(ErrorContextElement, TempErrorMessage) then begin
            ErrorMessageRegisterId := ErrorMessageHandler.RegisterErrorMessages(false);
            Rec."Error Message Register Id" := ErrorMessageRegisterId;
            Rec.Modify();
            Commit();
            ErrorMessageManagement.PopContext(ErrorContextElement);

            // throw last error
            LastError.Rethrow();
        end;

        // Commit any remaining transactions from the target codeunit\report. This is necessary due
        // to buffered record insertion which may not have surfaced errors in CODEUNIT.RUN above.
        Commit();
        OnAfterRun(Rec);
    end;

    local procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit(true);

        exit(Codeunit.Run(Codeunit::"Job Queue Start Report", JobQueueEntry));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}

