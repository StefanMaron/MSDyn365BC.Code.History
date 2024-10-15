table 10627 "SAFT Mapping Source"
{
    Caption = 'SAF-T Mapping Source';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Source Type"; Option)
        {
            OptionMembers = " ","Two Digit Standard Account","Four Digit Standard Account","Income Statement","Standard Tax Code";
        }
        field(3; "Source No."; Code[50])
        {
            Editable = false;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

