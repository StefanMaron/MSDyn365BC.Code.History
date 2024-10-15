table 31080 "Export Acc. Schedule"
{
    Caption = 'Export Acc. Schedule';
    DataCaptionFields = Name;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'The functionality will be removed and this table should not be used.';

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Account Schedule Name"; Code[10])
        {
            Caption = 'Account Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(10; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(20; "Show Amts. in Add. Curr."; Boolean)
        {
            Caption = 'Show Amts. in Add. Curr.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

