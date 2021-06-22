table 5921 "Fault Area/Symptom Code"
{
    Caption = 'Fault Area/Symptom Code';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',Fault Area,Symptom Code';
            OptionMembers = ,"Fault Area","Symptom Code";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Type, "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

