codeunit 10613 "E-Invoice Check Fin. Chrg.Memo"
{
    TableNo = "Finance Charge Memo Header";

    trigger OnRun()
    begin
        if "E-Invoice" then begin
            ReadCompanyInfo;
            ReadGLSetup;

            "Currency Code" := EInvoiceDocumentEncode.GetEInvoiceCurrencyCode("Currency Code");

            CompanyInfo.TestField(Name);
            CompanyInfo.TestField(Address);
            CompanyInfo.TestField(City);
            CompanyInfo.TestField("Post Code");
            CompanyInfo.TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

            CompanyInfo.TestField("VAT Registration No.");

            TestField(Name);
            TestField(Address);
            TestField(City);
            TestField("Post Code");
            TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Country/Region Code");
            TestField("VAT Registration No.");
            TestField("Your Reference");

            CheckFinChargeMemoLines(Rec);
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        CompanyInfoRead: Boolean;
        GLSetupRead: Boolean;
        EmptyDescErr: Label 'The Finance Charge Memo %1 contains lines in which the Type and the No. are specified, but the Description is empty. This is not allowed for an E-Invoice document which might be created from the posted document.';
        EmptyFieldsQst: Label 'The Finance Charge Memo %1 contains lines in which either the Type or the No. is empty. Lines that contain these empty fields are not taken into account when you create an E-Invoice document. Do you want to continue?';
        InterruptedIssuanceErr: Label 'The issuance of the document has been interrupted.';

    local procedure ReadCompanyInfo()
    begin
        if not CompanyInfoRead then begin
            CompanyInfo.Get();
            CompanyInfoRead := true;
        end;
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    local procedure CheckFinChargeMemoLines(FinChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        FinChargeMemoLine: Record "Finance Charge Memo Line";
        EmptyLineFound: Boolean;
    begin
        EmptyLineFound := false;
        with FinChargeMemoLine do begin
            Reset;
            SetRange("Finance Charge Memo No.", FinChargeMemoHeader."No.");
            if FindSet then
                repeat
                    if Description = '' then
                        if (Type <> Type::" ") and ("No." <> '') then
                            Error(EmptyDescErr, "Finance Charge Memo No.");
                    if (Type = Type::" ") or ("No." = '') then
                        EmptyLineFound := true;
                until (Next() = 0);

            if EmptyLineFound then
                if not Confirm(EmptyFieldsQst, true, "Finance Charge Memo No.") then
                    Error(InterruptedIssuanceErr);
        end;
    end;
}

