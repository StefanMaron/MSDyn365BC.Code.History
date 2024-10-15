table 31081 "Acc. Schedule Filter Line"
{
    Caption = 'Acc. Schedule Filter Line';
    DataCaptionFields = "Export Acc. Schedule Name";
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'The functionality will be removed and this table should not be used.';

    fields
    {
        field(1; "Export Acc. Schedule Name"; Code[10])
        {
            Caption = 'Export Acc. Schedule Name';
            Editable = false;
            TableRelation = "Export Acc. Schedule";
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Dimension 1 Filter"; Text[250])
        {
            Caption = 'Dimension 1 Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(11; "Dimension 2 Filter"; Text[250])
        {
            Caption = 'Dimension 2 Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(12; "Dimension 3 Filter"; Text[250])
        {
            Caption = 'Dimension 3 Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(13; "Dimension 4 Filter"; Text[250])
        {
            Caption = 'Dimension 4 Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(20; "Empty Column"; Boolean)
        {
            Caption = 'Empty Column';
        }
        field(25; Show; Boolean)
        {
            Caption = 'Show';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Export Acc. Schedule Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

