codeunit 12180 "FatturaPA Sales Validation"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        HeaderRecRef: RecordRef;
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog;

        HeaderRecRef.GetTable(Rec);
        FatturaDocHelper.CheckMandatoryFields(HeaderRecRef, ErrorMessage);
        ValidateSalesHeaderFields(Rec);

        if ErrorMessage.HasErrors(false) then
            ErrorMessage.ShowErrorMessages(true);
    end;

    var
        ErrorMessage: Record "Error Message";

    local procedure ValidateSalesHeaderFields(SalesHeader: Record "Sales Header")
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        // Sales Header mandatory fields

        if ErrorMessage.LogIfEmpty(SalesHeader,
             SalesHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Error) = 0
        then begin
            if PaymentMethod.Get(SalesHeader."Payment Method Code") then;
            ErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
        end;

        if (ErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Payment Terms Code"),
              ErrorMessage."Message Type"::Error) = 0) and PaymentTerms.Get(SalesHeader."Payment Terms Code")
        then
            ErrorMessage.LogIfEmpty(
              PaymentTerms, PaymentTerms.FieldNo("Fattura Payment Terms Code"), ErrorMessage."Message Type"::Error);

        OnAfterValidateSalesHeaderFields(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure AutoValidateDocument(RecordVariant: Variant; CustomerNo: Code[20]; UsageOption: Option)
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not Customer.Get(CustomerNo) then
            exit;

        if Customer."PA Code" = '' then
            exit;

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Fattura PA Electronic Format");

        ElectronicDocumentFormat.Code := SalesReceivablesSetup."Fattura PA Electronic Format";
        ElectronicDocumentFormat.Usage := "Report Selection Usage".FromInteger(UsageOption);
        ElectronicDocumentFormat.Find;
        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", RecordVariant);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterCheckSalesDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCheckSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DummyElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        SalesReceivablesSetup.Get();
        if not SalesReceivablesSetup."Validate Document On Posting" then
            exit;

        AutoValidateDocument(SalesHeader, SalesHeader."Sell-to Customer No.", DummyElectronicDocumentFormat.Usage::"Sales Validation".AsInteger());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesHeaderFields(SalesHeader: Record "Sales Header")
    begin
    end;
}

