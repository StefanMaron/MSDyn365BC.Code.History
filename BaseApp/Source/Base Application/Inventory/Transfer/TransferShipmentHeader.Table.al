﻿namespace Microsoft.Inventory.Transfer;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

table 5744 "Transfer Shipment Header"
{
    Caption = 'Transfer Shipment Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted Transfer Shipments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            CaptionClass = '5,7,' + "Trsf.-from Country/Region Code";
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            CaptionClass = '5,8,' + "Trsf.-to Country/Region Code";
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Posted Transfer Shipment"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(27; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(28; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
        }
        field(29; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location.Code where("Use As In-Transit" = const(true));
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(33; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if "Shipment Method Code" <> '' then
                    CheckShipAgentMethodComb();
                UpdateTDDPreparedBy();
            end;
        }
        field(34; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(35; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> '' then
                    CheckShipAgentMethodComb();
                if not ShipmentMethod.ThirdPartyLoader("Shipment Method Code") and
                  ("3rd Party Loader Type" <> "3rd Party Loader Type"::" ")
                then begin
                    "3rd Party Loader Type" := "3rd Party Loader Type"::" ";
                    "3rd Party Loader No." := '';
                end;
            end;
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(12100; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
        }
        field(12101; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(12102; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(12103; "Parcel Units"; Decimal)
        {
            Caption = 'Parcel Units';
            DecimalPlaces = 0 : 5;
        }
        field(12104; "Freight Type"; Option)
        {
            Caption = 'Freight Type';
            OptionCaption = 'Agent Code,Carriage Consigner,Carriage Forward';
            OptionMembers = "Agent Code","Carriage Consigner","Carriage Forward";
        }
        field(12174; "3rd Party Loader Type"; Option)
        {
            Caption = '3rd Party Loader Type';
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "3rd Party Loader Type" <> "3rd Party Loader Type"::" " then
                    ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
                if "3rd Party Loader Type" <> xRec."3rd Party Loader Type" then
                    "3rd Party Loader No." := '';
            end;
        }
        field(12175; "3rd Party Loader No."; Code[20])
        {
            Caption = '3rd Party Loader No.';
            TableRelation = if ("3rd Party Loader Type" = const(Vendor)) Vendor
            else
            if ("3rd Party Loader Type" = const(Contact)) Contact where(Type = filter(Company));

            trigger OnValidate()
            begin
                ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
            end;
        }
        field(12176; "Additional Information"; Text[50])
        {
            Caption = 'Additional Information';
        }
        field(12177; "Additional Notes"; Text[50])
        {
            Caption = 'Additional Notes';
        }
        field(12178; "Additional Instructions"; Text[50])
        {
            Caption = 'Additional Instructions';
        }
        field(12179; "TDD Prepared By"; Text[50])
        {
            Caption = 'TDD Prepared By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12180; "Transport Reason Code"; Code[10])
        {
            Caption = 'Transport Reason Code';
            TableRelation = "Transport Reason Code";
        }
        field(12181; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(12182; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(12183; "Goods Appearance"; Code[10])
        {
            Caption = 'Goods Appearance';
            TableRelation = "Goods Appearance";
        }
        field(12184; Volume; Decimal)
        {
            Caption = 'Volume';
        }
        field(12185; "Shipping Notes"; Text[100])
        {
            Caption = 'Shipping Notes';
        }
        field(12186; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(12187; "Shipping Starting Date"; Date)
        {
            Caption = 'Shipping Starting Date';
        }
        field(12188; "Shipping Starting Time"; Time)
        {
            Caption = 'Shipping Starting Time';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

    trigger OnDelete()
    var
        InvtCommentLine: Record "Inventory Comment Line";
        TransShptLine: Record "Transfer Shipment Line";
        MoveEntries: Codeunit MoveEntries;
    begin
        TransShptLine.SetRange("Document No.", "No.");
        if TransShptLine.Find('-') then
            repeat
                TransShptLine.Delete();
            until TransShptLine.Next() = 0;

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Transfer Shipment");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Transfer Shipment Line", 0, "No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Transfer Shipment Header", "No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Text12100: Label ' %1 %2 must be Vendor/Contact for %3 %4 3rd-Party Loader.';
        ShipmentMethod: Record "Shipment Method";

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
        TransShptHeader: Record "Transfer Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        TransShptHeader.Copy(Rec);
        ReportSelection.PrintWithDialogForCust(ReportSelection.Usage::Inv2, TransShptHeader, ShowRequestForm, 0);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    [Scope('OnPrem')]
    procedure StartTrackingSite()
    var
        Country: Record "Country/Region";
        ShippingAgent: Record "Shipping Agent";
        TrackingInternetAddr: Text[250];
    begin
        if "Trsf.-to Country/Region Code" <> '' then
            Country.Get("Trsf.-to Country/Region Code");
        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        TrackingInternetAddr :=
          StrSubstNo(
             ShippingAgent."Internet Address", "Package Tracking No.", Country.Name,
             "Shipment Date", ShippingAgent."Account No.");
        HyperLink(TrackingInternetAddr);
    end;

    local procedure UpdateTDDPreparedBy()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then begin
            if "TDD Prepared By" = '' then
                "TDD Prepared By" := UserId;
        end else
            "TDD Prepared By" := '';
    end;

    local procedure CheckShipAgentMethodComb()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") and
          not ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code")
        then
            Error(
              Text12100, FieldCaption("Shipping Agent Code"), "Shipping Agent Code",
              FieldCaption("Shipment Method Code"), "Shipment Method Code");
    end;

    [Scope('OnPrem')]
    procedure CheckTDDData(): Boolean
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        CheckShipAgentMethodComb();
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") then begin
            TestField("3rd Party Loader Type");
            TestField("3rd Party Loader No.");
        end else begin
            TestField("3rd Party Loader Type", "3rd Party Loader Type"::" ");
            TestField("3rd Party Loader No.", '');
        end;
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then begin
            TestField("TDD Prepared By");
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTDDAddr(var ShippingAgentAddr: array[8] of Text[100]; var LoaderAddr: array[8] of Text[100])
    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        Contact: Record Contact;
        ShippingAgent: Record "Shipping Agent";
    begin
        ShippingAgent.GetTDDAddr("Shipping Agent Code", ShippingAgentAddr);
        case "3rd Party Loader Type" of
            "3rd Party Loader Type"::Vendor:
                Vendor.GetTDDAddr("3rd Party Loader No.", LoaderAddr);
            "3rd Party Loader Type"::Contact:
                Contact.GetTDDAddr("3rd Party Loader No.", LoaderAddr);
            "3rd Party Loader Type"::" ":
                CompanyInfo.GetTDDAddr(LoaderAddr);
        end;
    end;

    procedure CopyFromTransferHeader(TransHeader: Record "Transfer Header")
    begin
        "Transfer-from Code" := TransHeader."Transfer-from Code";
        "Transfer-from Name" := TransHeader."Transfer-from Name";
        "Transfer-from Name 2" := TransHeader."Transfer-from Name 2";
        "Transfer-from Address" := TransHeader."Transfer-from Address";
        "Transfer-from Address 2" := TransHeader."Transfer-from Address 2";
        "Transfer-from Post Code" := TransHeader."Transfer-from Post Code";
        "Transfer-from City" := TransHeader."Transfer-from City";
        "Transfer-from County" := TransHeader."Transfer-from County";
        "Trsf.-from Country/Region Code" := TransHeader."Trsf.-from Country/Region Code";
        "Transfer-from Contact" := TransHeader."Transfer-from Contact";
        "Transfer-to Code" := TransHeader."Transfer-to Code";
        "Transfer-to Name" := TransHeader."Transfer-to Name";
        "Transfer-to Name 2" := TransHeader."Transfer-to Name 2";
        "Transfer-to Address" := TransHeader."Transfer-to Address";
        "Transfer-to Address 2" := TransHeader."Transfer-to Address 2";
        "Transfer-to Post Code" := TransHeader."Transfer-to Post Code";
        "Transfer-to City" := TransHeader."Transfer-to City";
        "Transfer-to County" := TransHeader."Transfer-to County";
        "Trsf.-to Country/Region Code" := TransHeader."Trsf.-to Country/Region Code";
        "Transfer-to Contact" := TransHeader."Transfer-to Contact";
        "Transfer Order Date" := TransHeader."Posting Date";
        "Posting Date" := TransHeader."Posting Date";
        "Shipment Date" := TransHeader."Shipment Date";
        "Receipt Date" := TransHeader."Receipt Date";
        "Shortcut Dimension 1 Code" := TransHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TransHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := TransHeader."Dimension Set ID";
        "Transfer Order No." := TransHeader."No.";
        "External Document No." := TransHeader."External Document No.";
        "In-Transit Code" := TransHeader."In-Transit Code";
        "Shipping Agent Code" := TransHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := TransHeader."Shipping Agent Service Code";
        "Shipment Method Code" := TransHeader."Shipment Method Code";
        "Transaction Type" := TransHeader."Transaction Type";
        "Transport Method" := TransHeader."Transport Method";
        "Partner VAT ID" := TransHeader."Partner VAT ID";
        "Entry/Exit Point" := TransHeader."Entry/Exit Point";
        Area := TransHeader.Area;
        "Transaction Specification" := TransHeader."Transaction Specification";
        "Direct Transfer" := TransHeader."Direct Transfer";
        "Net Weight" := TransHeader."Net Weight";
        "Gross Weight" := TransHeader."Gross Weight";
        "Parcel Units" := TransHeader."Parcel Units";
        "Package Tracking No." := TransHeader."Package Tracking No.";
        "Gross Weight" := TransHeader."Gross Weight";
        "Net Weight" := TransHeader."Net Weight";
        "Parcel Units" := TransHeader."Parcel Units";
        "Freight Type" := TransHeader."Freight Type";
        "Source Type" := TransHeader."Source Type";
        "Source No." := TransHeader."Source No.";
        "Goods Appearance" := TransHeader."Goods Appearance";
        Volume := TransHeader.Volume;
        "Shipping Notes" := TransHeader."Shipping Notes";
        "TDD Prepared By" := TransHeader."TDD Prepared By";

        OnAfterCopyFromTransferHeader(Rec, TransHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTransferHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var TransShptHeader: Record "Transfer Shipment Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;
}

