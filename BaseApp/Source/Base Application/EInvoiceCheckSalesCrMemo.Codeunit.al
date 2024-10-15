codeunit 10616 "E-Invoice Check Sales Cr. Memo"
{
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        EInvoiceCheckCommon: Codeunit "E-Invoice Check Common";
    begin
        CheckCompanyInfo;
        CheckSalesSetup;
        EInvoiceCheckCommon.CheckCurrencyCode("Currency Code", "No.", "Posting Date");
    end;

    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        InvalidPathErr: Label 'does not contain a valid path';

    local procedure CheckCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get;
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

        CompanyInfo.TestField("VAT Registration No.");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
    end;

    local procedure CheckSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        FileMgt: Codeunit "File Management";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path" := DelChr(SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path", '>', '\');
        SalesReceivablesSetup.TestField("E-Invoice Sales Cr. Memo Path");
        if not FileMgt.DirectoryExistsOnDotNetClient(SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path") then
            SalesReceivablesSetup.FieldError("E-Invoice Sales Cr. Memo Path", InvalidPathErr);
    end;
}

