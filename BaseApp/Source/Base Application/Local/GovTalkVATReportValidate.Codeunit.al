codeunit 10528 "GovTalk VAT Report Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"VAT Report Validate", Rec);
        ValidateGovTalkPrerequisites(Rec);
    end;

    var
        GovTalkSetupMissingErr: Label 'The GovTalk service is not completely set up. If you want to submit the report, go to the Service Connection page and fill in the the GovTalk setup fields.';

    [Scope('OnPrem')]
    procedure ValidateGovTalkPrerequisites(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        GovTalkSetup: Record "GovTalk Setup";
        CompanyInformation: Record "Company Information";
    begin
        ErrorMessage.SetContext(VATReportHeader);

        ErrorMessage.ClearLogRec(CompanyInformation);
        with CompanyInformation do begin
            Get();
            ErrorMessage.LogIfEmpty(CompanyInformation, FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(CompanyInformation, FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
            if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"EC Sales List" then begin
                ErrorMessage.LogIfEmpty(CompanyInformation, FieldNo("Branch Number"), ErrorMessage."Message Type"::Error);
                ErrorMessage.LogIfEmpty(CompanyInformation, FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
            end;
        end;
        ErrorMessage.CopyToTemp(TempErrorMessage);

        ErrorMessage.ClearLogRec(GovTalkSetup);
        with GovTalkSetup do begin
            if not FindFirst() then
                ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, GovTalkSetupMissingErr)
            else
                if (Username = '') or IsNullGuid(Password) or (Endpoint = '') then
                    ErrorMessage.LogMessage(GovTalkSetup, FieldNo(Username), ErrorMessage."Message Type"::Warning, GovTalkSetupMissingErr);
        end;
        ErrorMessage.CopyToTemp(TempErrorMessage);

        exit(not TempErrorMessage.HasErrors(false));
    end;
}

