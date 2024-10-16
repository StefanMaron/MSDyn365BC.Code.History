// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
#if not CLEAN22
using Microsoft.Inventory.Item;
#endif
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
#if not CLEAN22
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
#endif
using Microsoft.Projects.Project.Ledger;
#if not CLEAN22
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.History;
#endif

table 263 "Intrastat Jnl. Line"
{
    Caption = 'Intrastat Jnl. Line';
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
#if not CLEAN22
            TableRelation = "Intrastat Jnl. Template";
#endif
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
#if not CLEAN22
            TableRelation = "Intrastat Jnl. Batch".Name where("Journal Template Name" = field("Journal Template Name"));
#endif
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
#if not CLEAN22
            TableRelation = "Tariff Number";

            trigger OnValidate()
            begin
                GetItemDescription();
                Validate("Conversion Factor");
            end;
#endif
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

#if not CLEAN22
            trigger OnValidate()
            begin
                if Type = Type::Shipment then begin
                    "Country/Region of Origin Code" := GetCountryOfOriginCode();
                    "Partner VAT ID" := GetPartnerID();
                end;
            end;
#endif
        }
        field(12; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            Editable = false;
            TableRelation = if ("Source Type" = const("Item Entry")) "Item Ledger Entry"
            else
            if ("Source Type" = const("Job Entry")) "Job Ledger Entry";
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

#if not CLEAN22
            trigger OnValidate()
            begin
                if (Quantity <> 0) and Item.Get("Item No.") then
                    Validate("Net Weight", Item."Net Weight")
                else
                    Validate("Net Weight", 0);
                Validate("Conversion Factor");
            end;
#endif
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
#if not CLEAN22
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
                GetItemDescription();
                Validate("Conversion Factor");
            end;
#endif
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
        field(11315; "Conversion Factor"; Decimal)
        {
            Caption = 'Conversion Factor';
            Editable = false;

            trigger OnValidate()
            begin
                "No. of Supplementary Units" := Round(Quantity * "Conversion Factor", 0.00001);
            end;
        }
        field(11316; "Unit of Measure"; Text[10])
        {
            Caption = 'Unit of Measure';
            Editable = false;
        }
        field(11317; "No. of Supplementary Units"; Decimal)
        {
            Caption = 'No. of Supplementary Units';
            Editable = false;
        }
        field(11318; "Partner ID"; Text[50])
        {
            Caption = 'Partner ID';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Merged to W1';
            ObsoleteTag = '21.0';
            ObsoleteState = Removed;
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
        key(Key3; Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Transaction Specification", "Area", "Country/Region of Origin Code", "Partner VAT ID")
        {
        }
        key(Key4; "Internal Ref. No.")
        {
        }
        key(Key5; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

#if not CLEAN22
    trigger OnDelete()
    begin
        AssertBatchIsNotReported(Rec);
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
        Text11300: Label 'Please enter a conversion factor for tariffno. %1.', Comment = '%1 = Tariff No';

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
            "Conversion Factor" := TariffNumber."Conversion Factor";
            "Unit of Measure" := TariffNumber."Unit of Measure";
        end else begin
            "Item Description" := '';
            "Supplementary Units" := false;
            "Conversion Factor" := 0;
            "Unit of Measure" := ''
        end;
        if "Supplementary Units" then
            if "Conversion Factor" = 0 then
                Error(Text11300, "Tariff No.");
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
            IntrastatJnlBatch.FindFirst();
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

        if xRec.Type = Type::Receipt then
            IntrastatJnlBatch.TestField("System 19 reported", false)
        else
            IntrastatJnlBatch.TestField("System 29 reported", false);
    end;

    procedure GetCountryOfOriginCode() CountryOfOriginCode: Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        if not Item.Get("Item No.") then
            CountryOfOriginCode := ''
        else
            if Item."Country/Region of Origin Code" <> '' then
                CountryOfOriginCode := Item."Country/Region of Origin Code"
            else begin
                CompanyInformation.Get();
                if CompanyInformation."Country/Region Code" <> '' then
                    CountryOfOriginCode := CompanyInformation."Country/Region Code"
                else
                    CountryOfOriginCode := 'QU';
            end;
        OnAfterGetCountryOfOriginCode(Rec, CountryOfOriginCode);
    end;

    procedure GetPartnerID() PartnerID: Text[50]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPartnerID(Rec, PartnerID, IsHandled);
        if IsHandled then
            exit(PartnerID);

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
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        EU3rdPartyTrade: Boolean;
    begin
        if not ItemLedgerEntry.Get("Source Entry No.") then
            exit('');
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesInvoiceHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesCrMemoHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                if SalesShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesShipmentHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                if ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := ReturnReceiptHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code",
                        PurchCrMemoHdr."VAT Registration No.", PurchCrMemoHdr."Enterprise No.",
                        IsVendorPrivatePerson(PurchCrMemoHdr."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                if ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code",
                        ReturnShipmentHeader."VAT Registration No.", ReturnShipmentHeader."Enterprise No.",
                        IsVendorPrivatePerson(ReturnShipmentHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                if PurchRcptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Pay-to Country/Region Code",
                        PurchRcptHeader."VAT Registration No.", PurchRcptHeader."Enterprise No.",
                        IsVendorPrivatePerson(PurchRcptHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Service Shipment":
                if ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceShipmentHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code",
                        ServiceShipmentHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceShipmentHeader."Bill-to Customer No."), ServiceShipmentHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                if ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code",
                        ServiceInvoiceHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceInvoiceHeader."Bill-to Customer No."), ServiceInvoiceHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceCrMemoHeader."Bill-to Country/Region Code",
                        ServiceCrMemoHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceCrMemoHeader."Bill-to Customer No."), ServiceCrMemoHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Transfer Receipt":
                if TransferReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferReceiptHeader."Partner VAT ID", '', false, false));
            ItemLedgerEntry."Document Type"::"Transfer Shipment":
                if TransferShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferShipmentHeader."Partner VAT ID", '', false, false));
        end;

        if not IntrastatSetup.Get() then
            IntrastatSetup.Init();
        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    if not Customer.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code",
                        IntraJnlManagement.GetVATRegNo(
                          Customer."Country/Region Code", Customer."VAT Registration No.", IntrastatSetup."Cust. VAT No. on File"),
                        Customer."Enterprise No.", IsCustomerPrivatePerson(Customer."No."), EU3rdPartyTrade));
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    if not Vendor.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code",
                        IntraJnlManagement.GetVATRegNo(
                          Vendor."Country/Region Code", Vendor."VAT Registration No.", IntrastatSetup."Vend. VAT No. on File"),
                        Vendor."Enterprise No.", IsVendorPrivatePerson(Vendor."No."), false));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry() Result: Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        if not JobLedgerEntry.Get("Source Entry No.") then
            exit('');
        if not Job.Get(JobLedgerEntry."Job No.") then
            exit('');
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit('');
        if not IntrastatSetup.Get() then
            IntrastatSetup.Init();
        Result := GetPartnerIDForCountry(Customer."Country/Region Code", IntraJnlManagement.GetVATRegNo(Customer."Country/Region Code", Customer."VAT Registration No.", IntrastatSetup."Cust. VAT No. on File"), Customer."Enterprise No.", IsCustomerPrivatePerson(Customer."No."), false);
        OnAfterGetPartnerIDFromJobEntry(Rec, Customer, Result);
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Text[50]; EnterpriseNo: Text[50]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean): Text[50]
    var
        CountryRegion: Record "Country/Region";
        PartnerID: Text[50];
        IsHandled: Boolean;
    begin
        OnBeforeGetPartnerIDForCountry(CountryRegionCode, VATRegistrationNo, IsPrivatePerson, IsThirdPartyTrade, PartnerID, IsHandled);
        if IsHandled then
            exit(PartnerID);

        if IsPrivatePerson then
            exit('QV999999999999');

        CountryRegion.Get(CountryRegionCode);
        if CountryRegion.IsEUCountry(CountryRegionCode) then begin
            if VATRegistrationNo <> '' then
                exit(VATRegistrationNo);
            if EnterpriseNo <> '' then
                exit(EnterpriseNo);
        end;
        if IsThirdPartyTrade then
            exit('QV999999999999');

        exit('QV999999999999');
    end;

    protected procedure IsCustomerPrivatePerson(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then
            exit(false);
        if Customer."Intrastat Partner Type" <> Customer."Intrastat Partner Type"::" " then
            exit(Customer."Intrastat Partner Type" = Customer."Intrastat Partner Type"::Person)
        else
            exit(Customer."Partner Type" = Customer."Partner Type"::Person);
    end;

    protected procedure IsVendorPrivatePerson(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(VendorNo) then
            exit(false);
        if Vendor."Intrastat Partner Type" <> Vendor."Intrastat Partner Type"::" " then
            exit(Vendor."Intrastat Partner Type" = Vendor."Intrastat Partner Type"::Person)
        else
            exit(Vendor."Partner Type" = Vendor."Partner Type"::Person);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCountryOfOriginCode(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var CountryOfOriginCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPartnerIDFromJobEntry(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Customer: Record Customer; var Result: Text[50])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBatchIsNotReported(xIntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetItemDescription(var IsHandled: Boolean; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPartnerID(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var PartnerID: Text[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Text[50]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean; var PartnerID: Text[50]; var IsHandled: Boolean)
    begin
    end;
#endif
}

