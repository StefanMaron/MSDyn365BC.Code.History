codeunit 11301 "Localization Management"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GetCountryOfOriginCode(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
        CompanyInformation: Record "Company Information";
    begin
        Item.Get(ItemNo);
        if Item."Country/Region of Origin Code" <> '' then
            exit(Item."Country/Region of Origin Code");
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" <> '' then
            exit(CompanyInformation."Country/Region Code");
        exit('QU');
    end;

    [Scope('OnPrem')]
    procedure GetPartnerID(IntrastatJnlLine: Record "Intrastat Jnl. Line"): Text[50]
    begin
        with IntrastatJnlLine do
            case "Source Type" of
                "Source Type"::"Job Entry":
                    exit(GetPartnerIDFromJobEntry("Source Entry No."));
                "Source Type"::"Item Entry":
                    exit(GetPartnerIDFromItemEntry("Source Entry No."));
            end;
    end;

    local procedure GetPartnerIDFromItemEntry(SourceEntryNo: Integer): Text[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
    begin
        ItemLedgerEntry.Get(SourceEntryNo);
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                begin
                    SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        SalesInvoiceHeader."Bill-to Country/Region Code",
                        SalesInvoiceHeader."VAT Registration No.", SalesInvoiceHeader."Enterprise No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        SalesShipmentHeader."Bill-to Country/Region Code",
                        SalesShipmentHeader."VAT Registration No.", SalesShipmentHeader."Enterprise No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                begin
                    PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code",
                        PurchCrMemoHdr."VAT Registration No.", PurchCrMemoHdr."Enterprise No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                begin
                    ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code",
                        ReturnShipmentHeader."VAT Registration No.", ReturnShipmentHeader."Enterprise No."));
                end;
            ItemLedgerEntry."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    Customer.Get(ServiceShipmentHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code",
                        ServiceShipmentHeader."VAT Registration No.", Customer."Enterprise No."));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                begin
                    ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.");
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code",
                        ServiceInvoiceHeader."VAT Registration No.", Customer."Enterprise No."));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry(SourceEntryNo: Integer): Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
    begin
        JobLedgerEntry.Get(SourceEntryNo);
        Job.Get(JobLedgerEntry."Job No.");
        Customer.Get(Job."Bill-to Customer No.");
        exit(GetPartnerIDForCountry(Customer."Country/Region Code", Customer."VAT Registration No.", Customer."Enterprise No."));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; EnterpriseNo: Text[50]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        if CountryRegion.IsEUCountry(CountryRegionCode) then begin
            if VATRegistrationNo <> '' then
                exit(VATRegistrationNo);
            if EnterpriseNo <> '' then
                exit(EnterpriseNo);
        end;
        exit('QV999999999999');
    end;
}

