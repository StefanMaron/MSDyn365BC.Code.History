table 12152 "Subcontractor Prices"
{
    Caption = 'Subcontractor Prices';
    LookupPageID = "Subcontracting Prices";

    fields
    {
        field(1; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center"."No." WHERE("Subcontractor No." = FILTER(<> ''));
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                if Vendor.Get("Vendor No.") then
                    "Currency Code" := Vendor."Currency Code";
            end;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';
                end;
            end;
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(5; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                if ("Start Date" > "End Date") and ("End Date" <> 0D) then
                    Error(InvalidStartDateErr);
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                Validate("Start Date");
            end;
        }
        field(8; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
        field(9; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(12; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Start Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Vendor: Record Vendor;
        InvalidStartDateErr: Label 'The Start Date cannot be after the End Date.';
}

