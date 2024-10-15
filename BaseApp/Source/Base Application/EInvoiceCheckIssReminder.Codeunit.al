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
    begin
        SalesSetup.Get();
        SalesSetup.TestField("E-Invoice Reminder Path");
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

