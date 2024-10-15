table 12100 "Compress Depreciation"
{
    Caption = 'Compress Depreciation';

    fields
    {
        field(1; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = 'Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance,Salvage Value';
            OptionMembers = "Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance,"Salvage Value";
        }
        field(2; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
        }
        field(3; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(9; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(10; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "FA Posting Type", "FA Posting Group", "Depreciation Book Code", "Reason Code", "Document No.", "Posting Date", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Line No.", "FA Posting Group", "FA Posting Type")
        {
        }
    }

    fieldgroups
    {
    }
}

