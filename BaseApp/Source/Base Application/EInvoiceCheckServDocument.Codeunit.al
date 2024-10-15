codeunit 10623 "E-Invoice Check Serv. Document"
{
    TableNo = "Service Header";

    trigger OnRun()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
    begin
        if not "E-Invoice" then
            exit;

        ReadCompanyInfo;
        ReadGLSetup;

        EInvoiceDocumentEncode.GetEInvoiceCurrencyCode("Currency Code");

        if "Responsibility Center" <> '' then begin
            ResponsibilityCenter.Get("Responsibility Center");
            ResponsibilityCenter.TestField(Name);
            ResponsibilityCenter.TestField(Address);
            ResponsibilityCenter.TestField(City);
            ResponsibilityCenter.TestField("Post Code");
            ResponsibilityCenter.TestField("Country/Region Code");
        end else begin
            CompanyInfo.TestField(Name);
            CompanyInfo.TestField(Address);
            CompanyInfo.TestField(City);
            CompanyInfo.TestField("Post Code");
        end;
        CompanyInfo.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

        CompanyInfo.TestField("VAT Registration No.");

        TestField("Bill-to Name");
        TestField("Bill-to Address");
        TestField("Bill-to City");
        TestField("Bill-to Post Code");
        TestField("Bill-to Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Bill-to Country/Region Code");
        if ("Document Type" in ["Document Type"::Invoice, "Document Type"::Order, "Document Type"::"Credit Memo"]) and
           Customer.Get("Bill-to Customer No.")
        then
            Customer.TestField("VAT Registration No.");

        if "Document Type" = "Document Type"::"Credit Memo" then begin
            if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                TestField("Applies-to Doc. No.")
            else
                if "External Document No." = '' then
                    Error(MissingExternalDocNumberErr, "Document Type");
        end;

        TestField("VAT Registration No.");
        TestField("Your Reference");
        TestField("Ship-to Address");
        TestField("Ship-to City");
        TestField("Ship-to Post Code");
        TestField("Ship-to Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Ship-to Country/Region Code");
        TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");

        CheckServiceLines(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        GLSetupRead: Boolean;
        CompanyInfoRead: Boolean;
        EmptyFieldsQst: Label 'The %1 %2 contains lines in which either the Type, the No. or the Description is empty. Lines that contain these empty fields are not taken into account when you create an E-Invoice document. Do you want to continue?', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        EmptyUnitOfMeasureErr: Label 'The %1 %2 contains lines in which the Unit of Measure is empty. This is not allowed for an E-Invoice document which might be created from the posted document.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        MissingDescriptionErr: Label 'The %1 %2 contains lines in which the Type and the No. are specified, but the Description is empty. This is not allowed for an E-Invoice document which might be created from the posted document.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        MissingExternalDocNumberErr: Label 'You must specify an External document number in Document Type  = %1.  If you use E-Invoice, this field is required regardless of the value in the External Document No. field of the Service Mgt. Setup table.';
        MissingUnitOfMeasureCodeErr: Label 'You must specify a valid %2 for the %3 for %1.';
        PostingWasInterruptedErr: Label 'The posting has been interrupted.';

    local procedure ReadCompanyInfo()
    begin
        if not CompanyInfoRead then begin
            CompanyInfo.Get;
            CompanyInfoRead := true;
        end;
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get;
            GLSetupRead := true;
        end;
    end;

    local procedure CheckServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        UnitOfMeasure: Record "Unit of Measure";
        EmptyLineFound: Boolean;
    begin
        EmptyLineFound := false;
        with ServiceLine do begin
            SetRange("Document Type", ServiceHeader."Document Type");
            SetRange("Document No.", ServiceHeader."No.");
            if FindSet then
                repeat
                    if (Type <> Type::" ") and ("No." <> '') and ("Unit of Measure" = '') then
                        Error(EmptyUnitOfMeasureErr, "Document Type", "Document No.");
                    if Description = '' then
                        if (Type <> Type::" ") and ("No." <> '') then
                            Error(MissingDescriptionErr, "Document Type", "Document No.");
                    if (Type = Type::" ") or ("No." = '') then
                        EmptyLineFound := true;
                    if "Document Type" in ["Document Type"::Invoice, "Document Type"::Order, "Document Type"::"Credit Memo"] then begin
                        TestField("Unit of Measure Code");
                        UnitOfMeasure.Get("Unit of Measure Code");
                        if UnitOfMeasure."International Standard Code" = '' then
                            Error(
                              MissingUnitOfMeasureCodeErr, "Unit of Measure Code", UnitOfMeasure.FieldCaption("International Standard Code"),
                              UnitOfMeasure.TableCaption);
                    end;
                until (Next = 0);

            if EmptyLineFound then
                if not Confirm(EmptyFieldsQst, true, "Document Type", "Document No.") then
                    Error(PostingWasInterruptedErr);
        end;
    end;
}

