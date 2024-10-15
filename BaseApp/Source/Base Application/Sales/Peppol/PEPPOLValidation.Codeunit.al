namespace Microsoft.Sales.Peppol;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Utilities;

codeunit 1620 "PEPPOL Validation"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckSalesDocument(Rec);
        CheckSalesDocumentLines(Rec);
    end;

    var
        WrongLengthErr: Label 'should be %1 characters long';
        EmptyUnitOfMeasureErr: Label 'You must specify a valid International Standard Code for the Unit of Measure for %1.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order), 2 - document number';
        MissingDescriptionErr: Label 'Description field is empty. \Field must be filled if you want to send the posted document as an electronic document.', Comment = 'Parameter 1 - document type (), 2 - document number';
        PEPPOLManagement: Codeunit "PEPPOL Management";
        ConfirmManagement: Codeunit "Confirm Management";	
        MissingCompInfGLNOrVATRegNoOrEnterpNoErr: Label 'You must fill in either the GLN, VAT Registration No., or Enterprise No. field in the Company Information window.';
        MissingCustGLNOrVATRegNoOrEnterpNoErr: Label 'You must fill in either the GLN, VAT Registration No., or Enterprise No. field for customer %1.', Comment = '%1 - Customer No.';
        NegativeUnitPriceErr: Label 'The unit price is negative in %1. It cannot be negative if you want to send the posted document as an electronic document. \\Do you want to continue?', Comment = '%1 - record ID';

    local procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        with SalesHeader do begin
            CompanyInfo.Get();
            GLSetup.Get();

            IsHandled := false;
            OnBeforeCheckSalesDocument(SalesHeader, CompanyInfo, IsHandled);
            if IsHandled then
                exit;

            CheckCurrencyCode("Currency Code");

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
            CheckCountryRegionCode(CompanyInfo."Country/Region Code");

            IsHandled := false;
            OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader, CompanyInfo, IsHandled);
            if not IsHandled then
                if CompanyInfo.GLN + CompanyInfo."VAT Registration No." + CompanyInfo."Enterprise No." = '' then
                    Error(MissingCompInfGLNOrVATRegNoOrEnterpNoErr);
            TestField("Bill-to Name");
            TestField("Bill-to Address");
            TestField("Bill-to City");
            TestField("Bill-to Post Code");
            TestField("Bill-to Country/Region Code");
            CheckCountryRegionCode("Bill-to Country/Region Code");

            IsHandled := false;
            OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader, Customer, IsHandled);
            if not IsHandled then
                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::Order, "Document Type"::"Credit Memo"]) and
                   Customer.Get("Bill-to Customer No.")
                then
                if (Customer.GLN + Customer."VAT Registration No." + Customer."Enterprise No.") = '' then
                    Error(MissingCustGLNOrVATRegNoOrEnterpNoErr, Customer."No.");

            if "Document Type" = "Document Type"::"Credit Memo" then
                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    TestField("Applies-to Doc. No.");

            if "Document Type" in ["Document Type"::Invoice, "Document Type"::Order] then
                TestField("Shipment Date");
            TestField("Your Reference");
            CheckShipToAddress(SalesHeader);
            TestField("Due Date");

            if CompanyInfo.IBAN = '' then
                CompanyInfo.TestField("Bank Account No.");
            CompanyInfo.TestField("Bank Branch No.");
            CompanyInfo.TestField("SWIFT Code");
        end;

        OnAfterCheckSalesDocument(SalesHeader, CompanyInfo);
    end;

    local procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindSet() then
                repeat
                    CheckSalesDocumentLine(SalesLine)
                until Next() = 0;
        end;
    end;

    local procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLMgt: Codeunit "PEPPOL Management";
        unitCode: Text;
        unitCodeListID: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocumentLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        PEPPOLMgt.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
        with SalesLine do begin
            if (Type <> Type::" ") and ("No." <> '') and (unitCode = '') then
                Error(EmptyUnitOfMeasureErr, "Unit of Measure Code");

            IsHandled := false;
            OnCheckSalesDocumentLineOnBeforeCheckEmptyDescription(SalesLine, IsHandled);
            if not IsHandled then
                if CheckSalesLineTypeAndDescription(SalesLine) then
                    Error(MissingDescriptionErr);

            if (Type <> Type::" ") and ("No." <> '') then begin // Not a description line
                if GeneralLedgerSetup.UseVat() then
                    TestField("VAT Prod. Posting Group");
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                VATPostingSetup.TestField("Tax Category");
                if (Type = Type::Item) and ("Unit Price" < 0) then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(NegativeUnitPriceErr, RecordId), false) then
                        Error('');
            end;
        end;
    end;

    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        CheckSalesDocument(SalesHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesInvoiceLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                CheckSalesDocumentLine(SalesLine);
            until SalesInvoiceLine.Next() = 0;
    end;

    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesCrMemoHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        CheckSalesDocument(SalesHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                CheckSalesDocumentLine(SalesLine);
            until SalesCrMemoLine.Next() = 0;
    end;

    procedure CheckServiceHeader(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        CheckSalesDocument(SalesHeader);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceLine, SalesLine);
                OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(SalesLine, ServiceLine);
                CheckSalesDocumentLine(SalesLine);
            until ServiceLine.Next() = 0;
    end;

    procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        CheckSalesDocument(SalesHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(SalesLine, ServiceInvoiceLine);
                CheckSalesDocumentLine(SalesLine);
            until ServiceInvoiceLine.Next() = 0;
    end;

    procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        CheckSalesDocument(SalesHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(SalesLine, ServiceCrMemoLine);
                CheckSalesDocumentLine(SalesLine);
            until ServiceCrMemoLine.Next() = 0;
    end;

    local procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        MaxCurrencyCodeLength: Integer;
    begin
        MaxCurrencyCodeLength := 3;

        if CurrencyCode = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            CurrencyCode := GLSetup."LCY Code";
        end;

        if not Currency.Get(CurrencyCode) then begin
            if StrLen(CurrencyCode) <> MaxCurrencyCodeLength then
                GLSetup.FieldError("LCY Code", StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
            exit; // Valid
        end;

        if StrLen(Currency.Code) <> MaxCurrencyCodeLength then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
    end;

    local procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        CompanyInfo: Record "Company Information";
        MaxCountryCodeLength: Integer;
    begin
        MaxCountryCodeLength := 2;

        if CountryRegionCode = '' then begin
            CompanyInfo.Get();
            CompanyInfo.TestField("Country/Region Code");
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        CountryRegion.TestField("ISO Code");
        if StrLen(CountryRegion."ISO Code") <> MaxCountryCodeLength then
            CountryRegion.FieldError("ISO Code", StrSubstNo(WrongLengthErr, MaxCountryCodeLength));
    end;

    local procedure CheckShipToAddress(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipToAddress(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.TestField("Ship-to Address");
        SalesHeader.TestField("Ship-to City");
        SalesHeader.TestField("Ship-to Post Code");
        SalesHeader.TestField("Ship-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Ship-to Country/Region Code");
    end;

    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    begin
        if (SalesLine.Type <> SalesLine.Type::" ") and (SalesLine.Description = '') then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header"; CompanyInfo: Record "Company Information")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToAddress(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentLineOnBeforeCheckEmptyDescription(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocument(var SalesHeader: Record "Sales Header"; var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceInvoiceLine: Record "Service Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader: Record "Sales Header"; CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
}

