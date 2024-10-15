codeunit 10618 "E-Invoice Check Iss. Reminder"
{
    TableNo = "Issued Reminder Header";

    trigger OnRun()
    begin
        CheckCompanyInfo;
        CheckSalesSetup;
        CheckFinChargeMemoHeader(Rec);
    end;

    var
#if not CLEAN17
        InvalidPathErr: Label 'does not contain a valid path';
#endif
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";

    local procedure CheckCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");
        CompanyInfo.TestField("VAT Registration No.");
    end;

    local procedure CheckSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
#if not CLEAN17
        FileMgt: Codeunit "File Management";
#endif
    begin
        SalesSetup.Get();
        SalesSetup.TestField("E-Invoice Reminder Path");
#if not CLEAN17
        if not FileMgt.DirectoryExistsOnDotNetClient(SalesSetup."E-Invoice Reminder Path") then
            SalesSetup.FieldError("E-Invoice Reminder Path", InvalidPathErr);
#endif
    end;

    local procedure CheckFinChargeMemoHeader(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        with IssuedReminderHeader do begin
            TestField(Name);
            TestField(Address);
            TestField(City);
            TestField("Post Code");
            TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Country/Region Code");
        end;
    end;
}

