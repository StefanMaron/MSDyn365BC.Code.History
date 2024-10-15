﻿namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 5832 "Capacity Ledger Entry"
{
    Caption = 'Capacity Ledger Entry';
    DrillDownPageID = "Capacity Ledger Entries";
    LookupPageID = "Capacity Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center"
            else
            if (Type = const(Resource)) Resource;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; Type; Enum "Capacity Type Journal")
        {
            Caption = 'Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(9; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Stop Time"; Decimal)
        {
            Caption = 'Stop Time';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Output Quantity"; Decimal)
        {
            Caption = 'Output Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Scrap Quantity"; Decimal)
        {
            Caption = 'Scrap Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Concurrent Capacity"; Decimal)
        {
            Caption = 'Concurrent Capacity';
        }
        field(28; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(29; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Cap. Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(39; "Last Output Line"; Boolean)
        {
            Caption = 'Last Output Line';
        }
        field(42; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(43; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
        }
        field(44; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
        }
        field(52; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(53; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(56; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(57; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(58; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(59; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(65; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
            TableRelation = Stop;
        }
        field(66; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            TableRelation = Scrap;
        }
        field(68; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            TableRelation = "Work Center Group";
        }
        field(69; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            TableRelation = "Work Shift";
        }
        field(71; "Direct Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                          "Entry Type" = const("Direct Cost")));
            Caption = 'Direct Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                          "Entry Type" = const("Indirect Cost")));
            Caption = 'Overhead Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Direct Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                                "Entry Type" = const("Direct Cost")));
            Caption = 'Direct Cost (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Overhead Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                                "Entry Type" = const("Indirect Cost")));
            Caption = 'Overhead Cost (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
            TableRelation = if ("Order Type" = const(Production)) "Production Order"."No." where(Status = filter(Released ..));
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = filter(Released ..),
                                                                                                     "Prod. Order No." = field("Order No."));
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
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(11790; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Quantity, "Output Quantity";
        }
        key(Key4; "Work Center No.", "Work Shift Code", "Posting Date")
        {
        }
        key(Key5; Type, "No.", "Work Shift Code", "Item No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, Type, "No.", "Posting Date", "Document No.")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

    local procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure SetFilterByProdOrderRoutingLine(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ProdOrderRoutingNo: Code[20]; ProdOrderRoutingLineNo: Integer)
    begin
        SetRange("Order Type", "Order Type"::Production);
        SetRange("Order No.", ProdOrderNo);
        SetRange("Order Line No.", ProdOrderLineNo);
        SetRange("Routing No.", ProdOrderRoutingNo);
        SetRange("Routing Reference No.", ProdOrderRoutingLineNo);
    end;
}

