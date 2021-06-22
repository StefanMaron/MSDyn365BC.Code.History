table 7156 "Item Analysis View Budg. Entry"
{
    Caption = 'Item Analysis View Budg. Entry';
    DrillDownPageID = "Item Analy. View Budg. Entries";
    LookupPageID = "Item Analy. View Budg. Entries";

    fields
    {
        field(1; "Analysis Area"; Option)
        {
            Caption = 'Analysis Area';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Item Analysis View".Code WHERE("Analysis Area" = FIELD("Analysis Area"),
                                                             Code = FIELD("Analysis View Code"));
        }
        field(3; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "Item Budget Name".Name WHERE("Analysis Area" = FIELD("Analysis Area"));
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(5; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(6; "Source No."; Code[20])
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
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount';
        }
        field(23; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Budget Name", "Item No.", "Source Type", "Source No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Location Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        ItemAnalysisViewEntry.Init();
        ItemAnalysisViewEntry."Analysis Area" := "Analysis Area";
        ItemAnalysisViewEntry."Analysis View Code" := "Analysis View Code";
        exit(ItemAnalysisViewEntry.GetCaptionClass(AnalysisViewDimType));
    end;
}

