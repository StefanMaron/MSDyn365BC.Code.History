﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;

table 7342 "Posted Invt. Pick Header"
{
    Caption = 'Posted Invt. Pick Header';
    LookupPageID = "Posted Invt. Pick List";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;
        }
        field(4; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));
        }
        field(5; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
        }
        field(6; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
        }
        field(8; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(10; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Posted Invt. Pick"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Invt Pick No."; Code[20])
        {
            Caption = 'Invt Pick No.';
        }
        field(12; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7306; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(120)) "Purch. Rcpt. Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(110)) "Sales Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(6650)) "Return Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(6660)) "Return Receipt Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(5744)) "Transfer Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(5746)) "Transfer Receipt Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(5405)) "Production Order"."No." where(Status = filter(Released | Finished),
                                                                                                "No." = field("Source No."));
        }
        field(7307; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
        }
        field(7308; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(7309; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(7310; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
        }
        field(7311; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const(Family)) Family
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(7312; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(7314; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(7315; "External Document No.2"; Code[35])
        {
            Caption = 'External Document No.2';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Invt Pick No.")
        {
        }
        key(Key3; "Location Code")
        {
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        CheckLocation();

        PostedInvtPickLine.SetRange("No.", "No.");
        PostedInvtPickLine.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Posted Invt. Pick");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
#endif
    begin
        if "No." = '' then begin
            TestNoSeries();
            "No. Series" := GetNoSeriesCode();
#if not CLEAN24
            NoSeriesMgt.RaiseObsoleteOnBeforeInitSeries("No. Series", xRec."No. Series", "Posting Date", "No.", "No. Series", IsHandled);
            if not IsHandled then begin
#endif
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
#if not CLEAN24
                NoSeriesMgt.RaiseObsoleteOnAfterInitSeries("No. Series", GetNoSeriesCode(), "Posting Date", "No.");
            end;
#endif
        end;
        "Registering Date" := WorkDate();
    end;

    var
        InvtSetup: Record "Inventory Setup";

    local procedure CheckLocation()
    var
        Location: Record Location;
    begin
        Location.Get("Location Code");
        Location.TestField("Bin Mandatory", false);
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        InvtSetup.Get();
        exit(InvtSetup."Posted Invt. Pick Nos.");
    end;

    local procedure TestNoSeries()
    begin
        InvtSetup.Get();
        InvtSetup.TestField("Posted Invt. Pick Nos.");
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;
}

