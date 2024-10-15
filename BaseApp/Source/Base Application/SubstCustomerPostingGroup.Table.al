table 11781 "Subst. Customer Posting Group"
{
    Caption = 'Subst. Customer Posting Group';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Parent Cust. Posting Group"; Code[20])
        {
            Caption = 'Parent Cust. Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(2; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";

            trigger OnValidate()
            begin
                if "Customer Posting Group" = "Parent Cust. Posting Group" then
                    Error(PostGrpSubstErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Parent Cust. Posting Group", "Customer Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostGrpSubstErr: Label 'Posting Group cannot substitute itself.';
}

