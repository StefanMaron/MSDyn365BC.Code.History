table 10621 "SAFT Mapping Category"
{
    Caption = 'SAF-T Mapping Category';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Mapping Type"; Option)
        {
            OptionMembers = " ","Two Digit Standard Account","Four Digit Standard Account","Income Statement";
        }
        field(2; "No."; Code[20])
        {
        }
        field(3; Description; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Mapping Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }
}

