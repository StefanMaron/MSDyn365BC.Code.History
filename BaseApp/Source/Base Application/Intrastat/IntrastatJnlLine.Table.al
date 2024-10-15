﻿table 263 "Intrastat Jnl. Line"
{
    Caption = 'Intrastat Jnl. Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Intrastat Jnl. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Intrastat Jnl. Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            NotBlank = true;
            TableRelation = "Tariff Number";

            trigger OnValidate()
            begin
                GetItemDescription;
            end;
        }
        field(7; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(9; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(10; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(11; "Source Type"; Enum "Intrastat Source Type")
        {
            BlankZero = true;
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if Type = Type::Shipment then begin
                    "Country/Region of Origin Code" := GetCountryOfOriginCode();
                    "Partner VAT ID" := GetPartnerID();
                end;
            end;
        }
        field(12; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            Editable = false;
            TableRelation = IF ("Source Type" = CONST("Item Entry")) "Item Ledger Entry"
            ELSE
            IF ("Source Type" = CONST("Job Entry")) "Job Ledger Entry";
        }
        field(13; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                if Quantity <> 0 then
                    "Total Weight" := Round("Net Weight" * Quantity, 0.00001)
                else
                    "Total Weight" := 0;
            end;
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if "Cost Regulation %" <> 0 then
                    Validate("Cost Regulation %")
                else
                    "Statistical Value" := Amount + "Indirect Cost";
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if (Quantity <> 0) and Item.Get("Item No.") then
                    Validate("Net Weight", Item."Net Weight")
                else
                    Validate("Net Weight", 0);
            end;
        }
        field(16; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = -100;

            trigger OnValidate()
            begin
                "Indirect Cost" := Round(Amount * "Cost Regulation %" / 100, 1);
                "Statistical Value" := Round(Amount + "Indirect Cost", 1);
            end;
        }
        field(17; "Indirect Cost"; Decimal)
        {
            Caption = 'Indirect Cost';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                "Cost Regulation %" := 0;
                "Statistical Value" := Amount + "Indirect Cost";
            end;
        }
        field(18; "Statistical Value"; Decimal)
        {
            Caption = 'Statistical Value';
            DecimalPlaces = 0 : 0;
        }
        field(19; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                TestField("Source Type", 0);

                if "Item No." = '' then
                    Clear(Item)
                else
                    Item.Get("Item No.");

                Name := Item.Description;
                "Tariff No." := Item."Tariff No.";
                "Country/Region of Origin Code" := Item."Country/Region of Origin Code";
                GetItemDescription;
            end;
        }
        field(21; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(23; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
            Editable = false;
        }
        field(24; "Internal Ref. No."; Text[10])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(25; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(26; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(27; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(28; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(29; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(30; "Partner VAT ID"; Text[50])
        {
            Caption = 'Partner VAT ID';
        }
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(32; Counterparty; Boolean)
        {
            Caption = 'Counterparty';
        }
        field(13400; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure".Code;
        }
        field(13401; "Quantity 2"; Decimal)
        {
            Caption = 'Quantity 2';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Entry No.")
        {
        }
        key(Key3; Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID")
        {
            ObsoleteReason = 'Key7 should be used instead';
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
        }
        key(Key4; "Internal Ref. No.")
        {
            ObsoleteReason = 'Key6 should be used instead';
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
        }
        key(Key5; "Document No.")
        {
        }
        key(Key6; "Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.")
        {
        }
        key(Key7; "Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ErrorMessage: Record "Error Message";
    begin
        AssertBatchIsNotReported(Rec);
        ErrorMessage.SetContext(IntrastatJnlBatch);
        ErrorMessage.ClearLogRec(Rec);
    end;

    trigger OnInsert()
    begin
        IntraJnlTemplate.Get("Journal Template Name");
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
    end;

    trigger OnModify()
    begin
        AssertBatchIsNotReported(Rec);
    end;

    trigger OnRename()
    begin
        AssertBatchIsNotReported(xRec);
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        TariffNumber: Record "Tariff Number";

    local procedure GetItemDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemDescription(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Tariff No." <> '' then begin
            TariffNumber.Get("Tariff No.");
            "Item Description" := TariffNumber.Description;
            "Supplementary Units" := TariffNumber."Supplementary Units";
        end else
            "Item Description" := '';
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                IntrastatJnlBatch.SetFilter("Journal Template Name", TemplateFilter);
            IntrastatJnlBatch.SetFilter(Name, BatchFilter);
            IntrastatJnlBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    local procedure AssertBatchIsNotReported(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        CheckBatchIsNotReported(IntrastatJnlBatch);
    end;

    local procedure CheckBatchIsNotReported(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBatchIsNotReported(xRec, IntrastatJnlBatch, IsHandled);
        if IsHandled then
            exit;

        IntrastatJnlBatch.TestField(Reported, false);
    end;

    procedure GetCountryOfOriginCode(): Code[10]
    begin
        if not Item.Get("Item No.") then
            exit('');
        exit(Item."Country/Region of Origin Code");
    end;

    procedure GetPartnerID(): Text[50]
    begin
        case "Source Type" of
            "Source Type"::"Job Entry":
                exit(GetPartnerIDFromJobEntry());
            "Source Type"::"Item Entry":
                exit(GetPartnerIDFromItemEntry());
        end;
    end;

    local procedure GetPartnerIDFromItemEntry(): Text[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        Vendor: Record Vendor;
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        if not ItemLedgerEntry.Get("Source Entry No.") then
            exit('');
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesInvoiceHeader."Bill-to Country/Region Code", SalesInvoiceHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(SalesInvoiceHeader."Bill-to Customer No."), SalesInvoiceHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesCrMemoHeader."Bill-to Country/Region Code", SalesCrMemoHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(SalesCrMemoHeader."Bill-to Customer No."), SalesCrMemoHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                if SalesShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesShipmentHeader."Bill-to Country/Region Code", SalesShipmentHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(SalesShipmentHeader."Bill-to Customer No."), SalesShipmentHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                if ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnReceiptHeader."Bill-to Country/Region Code", ReturnReceiptHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ReturnReceiptHeader."Bill-to Customer No."), ReturnReceiptHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code", PurchCrMemoHdr."VAT Registration No.",
                        IsVendorPrivatePerson(PurchCrMemoHdr."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                if ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code", ReturnShipmentHeader."VAT Registration No.",
                        IsVendorPrivatePerson(ReturnShipmentHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                if PurchRcptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Pay-to Country/Region Code", PurchRcptHeader."VAT Registration No.",
                        IsVendorPrivatePerson(PurchRcptHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Service Shipment":
                if ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceShipmentHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code", ServiceShipmentHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceShipmentHeader."Bill-to Customer No."), ServiceShipmentHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                if ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceInvoiceHeader."Bill-to Customer No."), ServiceInvoiceHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceCrMemoHeader."Bill-to Country/Region Code", ServiceCrMemoHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceCrMemoHeader."Bill-to Customer No."), ServiceCrMemoHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Transfer Receipt":
                if TransferReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferReceiptHeader."Partner VAT ID", false, false));
            ItemLedgerEntry."Document Type"::"Transfer Shipment":
                if TransferShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferShipmentHeader."Partner VAT ID", false, false));
        end;

        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    Customer.Get(ItemLedgerEntry."Source No.");
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Customer."VAT Registration No.",
                        Customer."Partner Type" = Customer."Partner Type"::Person, false));
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    Vendor.Get(ItemLedgerEntry."Source No.");
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Vendor."VAT Registration No.",
                        Vendor."Partner Type" = Vendor."Partner Type"::Person, false));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry(): Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
    begin
        if not JobLedgerEntry.Get("Source Entry No.") then
            exit('');
        if not Job.Get(JobLedgerEntry."Job No.") then
            exit('');
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit('');
        exit(
          GetPartnerIDForCountry(
            Customer."Country/Region Code", Customer."VAT Registration No.",
            Customer."Partner Type" = Customer."Partner Type"::Person, false));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        if IsPrivatePerson then
            exit('QV999999999999');

        if IsThirdPartyTrade then
            exit('QV999999999999');

        if (CountryRegionCode <> '') and CountryRegion.Get(CountryRegionCode) then
            if CountryRegion.IsEUCountry(CountryRegionCode) then
                if VATRegistrationNo <> '' then
                    exit(VATRegistrationNo);

        exit('QV999999999999');
    end;

    local procedure IsCustomerPrivatePerson(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer."Partner Type" = Customer."Partner Type"::Person);
        exit(false);
    end;

    local procedure IsVendorPrivatePerson(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor."Partner Type" = Vendor."Partner Type"::Person);
        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBatchIsNotReported(xIntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetItemDescription(var IsHandled: Boolean; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;
}

