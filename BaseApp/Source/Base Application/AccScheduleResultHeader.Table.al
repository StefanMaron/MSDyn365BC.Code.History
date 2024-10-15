table 31086 "Acc. Schedule Result Header"
{
    Caption = 'Acc. Schedule Result Header';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Date Filter"; Text[30])
        {
            Caption = 'Date Filter';
        }
        field(4; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Acc. Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(5; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
        }
        field(12; "Dimension 1 Filter"; Text[50])
        {
            Caption = 'Dimension 1 Filter';
        }
        field(13; "Dimension 2 Filter"; Text[50])
        {
            Caption = 'Dimension 2 Filter';
        }
        field(14; "Dimension 3 Filter"; Text[50])
        {
            Caption = 'Dimension 3 Filter';
        }
        field(15; "Dimension 4 Filter"; Text[50])
        {
            Caption = 'Dimension 4 Filter';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(21; "Result Date"; Date)
        {
            Caption = 'Result Date';
            Editable = false;
        }
        field(22; "Result Time"; Time)
        {
            Caption = 'Result Time';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Result Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

