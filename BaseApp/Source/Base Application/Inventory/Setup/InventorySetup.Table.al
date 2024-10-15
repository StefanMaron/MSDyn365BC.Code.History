﻿namespace Microsoft.Inventory.Setup;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Upgrade;
using System.Utilities;
using System.Globalization;

table 313 "Inventory Setup"
{
    Caption = 'Inventory Setup';
    Permissions = TableData "Inventory Adjmt. Entry (Order)" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Automatic Cost Posting"; Boolean)
        {
            Caption = 'Automatic Cost Posting';
        }
        field(3; "Location Mandatory"; Boolean)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Mandatory';
        }
        field(4; "Item Nos."; Code[20])
        {
            Caption = 'Item Nos.';
            TableRelation = "No. Series";
        }
        field(30; "Automatic Cost Adjustment"; Enum "Automatic Cost Adjustment Type")
        {
            Caption = 'Automatic Cost Adjustment';

            trigger OnValidate()
            begin
                if "Automatic Cost Adjustment" <> "Automatic Cost Adjustment"::Never then begin
                    Item.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
                    Item.SetRange("Cost is Adjusted", false);
                    Item.SetRange("Allow Online Adjustment", false);

                    UpdateItem();
                    UpdateInvtAdjmtEntryOrder();

                    InvtAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
                    InvtAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
                    InvtAdjmtEntryOrder.SetRange("Allow Online Adjustment", false);
                    InvtAdjmtEntryOrder.SetRange("Is Finished", true);

                    if not (Item.IsEmpty() and InvtAdjmtEntryOrder.IsEmpty) then
                        Message(Text000);
                end;
            end;
        }
        field(31; "Cost Adjustment Logging"; Enum "Cost Adjustment Logging Level")
        {
            Caption = 'Cost Adjustment Logging';
            DataClassification = CustomerContent;
        }
        field(40; "Prevent Negative Inventory"; Boolean)
        {
            Caption = 'Prevent Negative Inventory';
        }
        field(45; "Variant Mandatory if Exists"; Boolean)
        {
            Caption = 'Variant Mandatory if Exists';
        }
        field(50; "Skip Prompt to Create Item"; Boolean)
        {
            Caption = 'Skip Prompt to Create Item';
            DataClassification = SystemMetadata;
        }
        field(51; "Copy Item Descr. to Entries"; Boolean)
        {
            Caption = 'Copy Item Descr. to Entries';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Item Descr. to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(60; "Allow Inventory Adjustment"; Boolean)
        {
            Caption = 'Allow Inventory Adjustment';
            InitValue = true;
        }
        field(180; "Invt. Cost Jnl. Template Name"; Code[10])
        {
            Caption = 'Invt. Cost Jnl. Template Name';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                if "Invt. Cost Jnl. Template Name" = '' then
                    "Invt. Cost Jnl. Batch Name" := '';
            end;
        }
        field(181; "Invt. Cost Jnl. Batch Name"; Code[10])
        {
            Caption = 'Jnl. Batch Name Cost Posting';
            TableRelation = if ("Invt. Cost Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Invt. Cost Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Invt. Cost Jnl. Template Name");
            end;
        }
        field(5700; "Transfer Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Transfer Order Nos.';
            TableRelation = "No. Series";
        }
        field(5701; "Posted Transfer Shpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Posted Transfer Shpt. Nos.';
            TableRelation = "No. Series";
        }
        field(5702; "Posted Transfer Rcpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Posted Transfer Rcpt. Nos.';
            TableRelation = "No. Series";
        }
        field(5703; "Copy Comments Order to Shpt."; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Copy Comments Order to Shpt.';
            InitValue = true;
        }
        field(5704; "Copy Comments Order to Rcpt."; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Copy Comments Order to Rcpt.';
            InitValue = true;
        }
        field(5718; "Nonstock Item Nos."; Code[20])
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Catalog Item Nos.';
            TableRelation = "No. Series";
        }
        field(5725; "Use Item References"; Boolean)
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Use Item References';
            ObsoleteReason = 'Replaced by default visibility for Item Reference''s fields and actions.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5790; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
        }
        field(5791; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
        }
        field(5800; "Expected Cost Posting to G/L"; Boolean)
        {
            Caption = 'Expected Cost Posting to G/L';

            trigger OnValidate()
            var
                ChangeExpCostPostToGL: Codeunit "Change Exp. Cost Post. to G/L";
            begin
                if "Expected Cost Posting to G/L" <> xRec."Expected Cost Posting to G/L" then
                    if ItemLedgEntry.FindFirst() then begin
                        ChangeExpCostPostToGL.ChangeExpCostPostingToGL(Rec, "Expected Cost Posting to G/L");
                        Find();
                    end;
            end;
        }
        field(5801; "Default Costing Method"; Enum "Costing Method")
        {
            Caption = 'Default Costing Method';
        }
        field(5804; "Average Cost Calc. Type"; Enum "Average Cost Calculation Type")
        {
            Caption = 'Average Cost Calc. Type';
            InitValue = "Item & Location & Variant";
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField("Average Cost Calc. Type");
                if "Average Cost Calc. Type" <> xRec."Average Cost Calc. Type" then
                    UpdateAvgCostItemSettings(FieldCaption("Average Cost Calc. Type"), Format("Average Cost Calc. Type"));
            end;
        }
        field(5805; "Average Cost Period"; Option)
        {
            Caption = 'Average Cost Period';
            InitValue = Day;
            NotBlank = true;
            OptionCaption = ' ,Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = " ",Day,Week,Month,Quarter,Year,"Accounting Period";

            trigger OnValidate()
            begin
                TestField("Average Cost Period");
                if "Average Cost Period" <> xRec."Average Cost Period" then
                    UpdateAvgCostItemSettings(FieldCaption("Average Cost Period"), Format("Average Cost Period"));
            end;
        }
        field(5849; "Allow Invt. Doc. Reservation"; Boolean)
        {
            Caption = 'Allow Invt. Doc. Reservation';
        }
        field(5850; "Invt. Receipt Nos."; Code[20])
        {
            Caption = 'Invt. Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(5851; "Posted Invt. Receipt Nos."; Code[20])
        {
            Caption = 'Posted Invt. Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(5852; "Invt. Shipment Nos."; Code[20])
        {
            Caption = 'Invt. Shipment Nos.';
            TableRelation = "No. Series";
        }
        field(5853; "Posted Invt. Shipment Nos."; Code[20])
        {
            Caption = 'Posted Invt. Shipment Nos.';
            TableRelation = "No. Series";
        }
        field(5854; "Copy Comments to Invt. Doc."; Boolean)
        {
            Caption = 'Copy Comments to Invt. Doc.';
        }
        field(5855; "Direct Transfer Posting"; Option)
        {
            Caption = 'Direct Transfer Posting';
            OptionCaption = 'Receipt and Shipment,Direct Transfer';
            OptionMembers = "Receipt and Shipment","Direct Transfer";
        }
        field(5856; "Posted Direct Trans. Nos."; Code[20])
        {
            Caption = 'Posted Direct Trans. Nos.';
            TableRelation = "No. Series";
        }
        field(5860; "Package Nos."; Code[20])
        {
            Caption = 'Package Nos.';
            TableRelation = "No. Series";
        }
        field(5875; "Phys. Invt. Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Phys. Invt. Order Header" = R;
            Caption = 'Phys. Invt. Order Nos.';
            TableRelation = "No. Series";
        }
        field(5876; "Posted Phys. Invt. Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Phys. Invt. Order Header" = R;
            Caption = 'Posted Phys. Invt. Order Nos.';
            TableRelation = "No. Series";
        }
        field(5877; "Invt. Orders Package Tracking"; Boolean)
        {
            Caption = 'Invt. Orders Package Tracking';
            ObsoleteReason = 'Temporary setup to enable/disable package tracking in Phys. Inventory Orders';
#if not CLEAN24
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#endif
        }
        field(6500; "Package Caption"; Text[30])
        {
            Caption = 'Package Caption';
        }
        field(7101; "Item Group Dimension Code"; Code[20])
        {
            Caption = 'Item Group Dimension Code';
            TableRelation = Dimension;
        }
        field(7300; "Inventory Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Inventory Put-away Nos.';
            TableRelation = "No. Series";
        }
        field(7301; "Inventory Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Inventory Pick Nos.';
            TableRelation = "No. Series";
        }
        field(7302; "Posted Invt. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Posted Invt. Put-away Nos.';
            TableRelation = "No. Series";
        }
        field(7303; "Posted Invt. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Posted Invt. Pick Nos.';
            TableRelation = "No. Series";
        }
        field(7304; "Inventory Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Inventory Movement Nos.';
            TableRelation = "No. Series";
        }
        field(7305; "Registered Invt. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Registered Invt. Movement Nos.';
            TableRelation = "No. Series";
        }
        field(7306; "Internal Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Internal Movement Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ObjTransl: Record "Object Translation";
        RecordHasBeenRead: Boolean;

        Text000: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        Text004: Label 'The program has cancelled the change that would have caused an adjustment of all items.';
        Text005: Label '%1 has been changed to %2. You should now run %3.';
        ItemEntriesAdjustQst: Label 'If you change the %1, the program must adjust all item entries.The adjustment of all entries can take several hours.\Do you really want to change the %1?', Comment = '%1 - field caption';

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    local procedure UpdateInvtAdjmtEntryOrder()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InvtAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        InvtAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InvtAdjmtEntryOrder.SetRange("Allow Online Adjustment", false);
        InvtAdjmtEntryOrder.SetRange("Is Finished", false);
        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
        InvtAdjmtEntryOrder.ModifyAll("Allow Online Adjustment", true);
    end;

    local procedure UpdateItem()
    var
        LocalItem: Record Item;
    begin
        LocalItem.Copy(Item);
        LocalItem.SetRange("Allow Online Adjustment", false);
        if not LocalItem.IsEmpty() then
            LocalItem.ModifyAll("Allow Online Adjustment", true);
    end;

    local procedure UpdateAvgCostItemSettings(FieldCaption: Text[80]; FieldValue: Text[80])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ItemEntriesAdjustQst, FieldCaption), false)
        then
            Error(Text004);

        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", Rec);

        Message(
          Text005, FieldCaption, FieldValue,
          ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Adjust Cost - Item Entries"));
    end;

    procedure OptimGLEntLockForMultiuserEnv(): Boolean
    begin
        if Rec.Get() then
            if Rec."Automatic Cost Posting" then
                exit(false);

        exit(true);
    end;

    procedure AutomaticCostAdjmtRequired(): Boolean
    begin
        exit("Automatic Cost Adjustment" <> "Automatic Cost Adjustment"::Never);
    end;
}

