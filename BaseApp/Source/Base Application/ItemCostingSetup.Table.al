table 12132 "Item Costing Setup"
{
    Caption = 'Item Costing Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Components Valuation"; Option)
        {
            Caption = 'Components Valuation';
            OptionCaption = 'Average Cost,Weighted Average Cost';
            OptionMembers = "Average Cost","Weighted Average Cost";
        }
        field(3; "Estimated WIP Consumption"; Boolean)
        {
            Caption = 'Estimated WIP Consumption';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

