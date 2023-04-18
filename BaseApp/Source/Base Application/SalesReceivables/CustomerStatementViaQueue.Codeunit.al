codeunit 8811 "Customer Statement via Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
        XmlContent: Text;
    begin
        CalcFields("Object Caption to Run");
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        ErrorMessageManagement.PushContext(ErrorContextElement, RecordId, 0, "Object Caption to Run");

        XmlContent := GetXmlContent();
        if XmlContent = '' then
            ErrorMessageManagement.LogErrorMessage(0, RequestParametersHasNotBeenSetErr, Rec, FieldNo(XML), '')
        else
            CustomerLayoutStatement.RunReportWithParameters(XmlContent);

        ErrorMessageHandler.AppendTo(TempErrorMessage);
        LogErrors(TempErrorMessage, Rec);
        ErrorMessageManagement.PopContext(ErrorContextElement);
    end;

    var
        RequestParametersHasNotBeenSetErr: Label 'Request parameters for the Standard Statement report have not been set up.';

    local procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityTitle: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(
            RelatedRecordID, ActivityLog.Status::Failed, ActivityTitle,
            ActivityMessage, '');
    end;

    local procedure LogErrors(var TempErrorMessage: Record "Error Message" temporary; var JobQueueEntry: Record "Job Queue Entry")
    begin
        if TempErrorMessage.FindSet() then
            repeat
                LogActivityFailed(JobQueueEntry.RecordID, JobQueueEntry."Object Caption to Run", TempErrorMessage."Message");
            until TempErrorMessage.Next() = 0;
    end;
}

