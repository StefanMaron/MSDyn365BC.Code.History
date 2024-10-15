table 31041 "Depreciation Group"
{
    Caption = 'Depreciation Group';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '21.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Depreciation Type"; Option)
        {
            Caption = 'Depreciation Type';
            OptionCaption = 'Straight-line,Declining-Balance,Straight-line Intangible';
            OptionMembers = "Straight-line","Declining-Balance","Straight-line Intangible";
        }
        field(6; "No. of Depreciation Years"; Integer)
        {
            Caption = 'No. of Depreciation Years';

            trigger OnValidate()
            begin
                "No. of Depreciation Months" := Round("No. of Depreciation Years" * 12, 0.00000001);
            end;
        }
        field(7; "No. of Depreciation Months"; Decimal)
        {
            Caption = 'No. of Depreciation Months';

            trigger OnValidate()
            begin
                "No. of Depreciation Years" := Round("No. of Depreciation Months" / 12, 1);
            end;
        }
        field(8; "Min. Months After Appreciation"; Decimal)
        {
            Caption = 'Min. Months After Appreciation';
        }
        field(10; "Straight First Year"; Decimal)
        {
            Caption = 'Straight First Year';
            DecimalPlaces = 0 : 15;
        }
        field(11; "Straight Next Years"; Decimal)
        {
            Caption = 'Straight Next Years';
            DecimalPlaces = 0 : 15;
        }
        field(12; "Straight Appreciation"; Decimal)
        {
            Caption = 'Straight Appreciation';
            DecimalPlaces = 0 : 15;
        }
        field(13; "Declining First Year"; Decimal)
        {
            Caption = 'Declining First Year';
            DecimalPlaces = 0 : 15;
        }
        field(14; "Declining Next Years"; Decimal)
        {
            Caption = 'Declining Next Years';
            DecimalPlaces = 0 : 15;
        }
        field(15; "Declining Appreciation"; Decimal)
        {
            Caption = 'Declining Appreciation';
            DecimalPlaces = 0 : 15;
        }
        field(16; "Declining Depr. Increase %"; Decimal)
        {
            Caption = 'Declining Depr. Increase %';
            DecimalPlaces = 0 : 15;
        }
        field(17; "Depreciation Group"; Text[10])
        {
            Caption = 'Depreciation Group';
        }
    }

    keys
    {
        key(Key1; "Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Starting Date", Description, "Depreciation Type", "No. of Depreciation Years", "No. of Depreciation Months")
        {
        }
    }
}
