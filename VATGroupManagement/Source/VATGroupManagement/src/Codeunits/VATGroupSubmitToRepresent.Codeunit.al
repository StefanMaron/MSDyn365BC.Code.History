codeunit 4706 "VAT Group Submit To Represent."
{
    TableNo = "VAT Report Header";

    var
        VATGroupSubmissionsEndPointTxt: Label '/vatGroupSubmissions?$expand=vatGroupSubmissionLines', Locked = true;
        NoVATReportSetupErr: Label 'The VAT report setup was not found. You can create one on the VAT Report Setup page.';
        SubmitMembersOnlyErr: Label 'You must be configured as a VAT Group member in order to submit VAT returns to the group representative.';

    trigger OnRun()
    var
        VATReportSetup: Record "VAT Report Setup";
        ErrorMessage: Record "Error Message";
        VATGroupSerialization: Codeunit "VAT Group Serialization";
        VATGroupCommunication: Codeunit "VAT Group Communication";
        HttpResponseBodyText: Text;
        ContentJsonText: Text;

    begin
        if not VATReportSetup.Get() then
            Error(NoVATReportSetupErr);

        if not VATReportSetup.IsGroupMember() then
            Error(SubmitMembersOnlyErr);

        VATGroupSerialization.CreateVATSubmissionJson(Rec).WriteTo(ContentJsonText);

        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog();
        if not VATGroupCommunication.Send('POST', VATGroupSubmissionsEndPointTxt, ContentJsonText, HttpResponseBodyText, false) then begin
            ErrorMessage.LogLastError();
            if HttpResponseBodyText <> '' then
                ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, HttpResponseBodyText);
        end;

        if ErrorMessage.HasErrors(true) then
            exit;

        Rec.Validate(Status, Rec.Status::Submitted);
        Rec.Modify(true);
    end;
}