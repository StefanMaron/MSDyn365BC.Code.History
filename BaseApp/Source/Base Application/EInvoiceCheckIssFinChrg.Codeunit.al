codeunit 10617 "E-Invoice Check Iss. Fin.Chrg."
{
    TableNo = "Issued Fin. Charge Memo Header";

    trigger OnRun()
    begin
        CheckCompanyInfo;
        CheckSalesSetup;
        CheckFinChargeMemoHeader(Rec);
    end;

    var
        InvalidPathErr: Label 'does not contain a valid path';
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";

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
    end;

    local procedure CheckSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        FileMgt: Codeunit "File Management";
    begin
        SalesSetup.Get;
        SalesSetup.TestField("E-Invoice Fin. Charge Path");
        if not FileMgt.DirectoryExistsOnDotNetClient(SalesSetup."E-Invoice Fin. Charge Path") then
            SalesSetup.FieldError("E-Invoice Fin. Charge Path", InvalidPathErr);
    end;

    local procedure CheckFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        with IssuedFinChargeMemoHeader do begin
            TestField(Name);
            TestField(Address);
            TestField(City);
            TestField("Post Code");
            TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Country/Region Code");
        end;
    end;
}

