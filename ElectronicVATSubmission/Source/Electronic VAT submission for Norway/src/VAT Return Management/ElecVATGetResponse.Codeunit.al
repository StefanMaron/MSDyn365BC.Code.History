codeunit 10690 "Elec. VAT Get Response"
{
    TableNo = "VAT Report Header";

    var
        NoFeedbackProvidedMsg: Label 'The feedback for your submission is not ready yet.';
        ReportAcceptedMsg: Label 'The report has been successfully accepted.';
        ReportRejectedMsg: Label 'The report was rejected. To find out why, download the response message and check the attached documents.';

    trigger OnRun()
    var
        ElecVATConnectionMgt: Codeunit "Elec. VAT Connection Mgt.";
    begin
        if not ElecVATConnectionMgt.IsFeedbackProvided(Rec) then begin
            message(NoFeedbackProvidedMsg);
            exit;
        end;
        if ElecVATConnectionMgt.IsVATReportAccepted(Rec) then begin
            Validate(Status, Status::Accepted);
            Message(ReportAcceptedMsg);
        end else begin
            Validate(Status, Status::Rejected);
            Message(ReportRejectedMsg);
        end;
        Modify(true);
    end;
}