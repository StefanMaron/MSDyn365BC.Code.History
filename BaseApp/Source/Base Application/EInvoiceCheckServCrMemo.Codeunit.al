codeunit 10625 "E-Invoice Check Serv. Cr. Memo"
{
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        EInvoiceCheckCommon: Codeunit "E-Invoice Check Common";
    begin
        CheckCompanyInfo;
        CheckServiceMgtSetup;
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

    local procedure CheckServiceMgtSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        FileMgt: Codeunit "File Management";
    begin
        ServiceMgtSetup.Get;

        ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path" := DelChr(ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path", '>', '\');
        ServiceMgtSetup.TestField("E-Invoice Serv. Cr. Memo Path");
        if not FileMgt.DirectoryExistsOnDotNetClient(ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path") then
            ServiceMgtSetup.FieldError("E-Invoice Serv. Cr. Memo Path", InvalidPathErr);
    end;
}

