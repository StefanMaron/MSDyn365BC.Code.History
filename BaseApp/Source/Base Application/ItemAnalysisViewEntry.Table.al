table 7154 "Item Analysis View Entry"
{
    Caption = 'Item Analysis View Entry';
    DrillDownPageID = "Item Analysis View Entries";
    LookupPageID = "Item Analysis View Entries";

    fields
    {
        field(1; "Analysis Area"; Option)
        {
            Caption = 'Analysis Area';
            OptionCaption = 'Sales,Purchase,Inventory';
            OptionMembers = Sales,Purchase,Inventory;
        }
        field(2; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Item Analysis View".Code WHERE("Analysis Area" = FIELD("Analysis Area"),
                                                             Code = FIELD("Analysis View Code"));
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(9; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        field(10; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        field(11; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(13; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(14; "Item Ledger Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Item Ledger Entry Type';
        }
        field(15; "Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(21; "Invoiced Quantity"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Invoiced Quantity';
        }
        field(22; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount (Actual)';
        }
        field(23; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Actual)';
        }
        field(24; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AccessByPermission = TableData "Item Charge" = R;
            AutoFormatType = 1;
            Caption = 'Cost Amount (Non-Invtbl.)';
        }
        field(31; Quantity; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Quantity';
        }
        field(32; "Sales Amount (Expected)"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatType = 1;
            Caption = 'Sales Amount (Expected)';
        }
        field(33; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Expected)';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Item No.", "Item Ledger Entry Type", "Entry Type", "Source Type", "Source No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Location Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
        ItemAnalysisView: Record "Item Analysis View";

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if (ItemAnalysisView."Analysis Area" <> "Analysis Area") or
           (ItemAnalysisView.Code <> "Analysis View Code")
        then
            ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 1 Code");
                    exit(Text000);
                end;
            2:
                begin
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 2 Code");
                    exit(Text001);
                end;
            3:
                begin
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 3 Code");
                    exit(Text002);
                end;
        end;
    end;
}

