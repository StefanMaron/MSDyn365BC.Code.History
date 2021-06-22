table 800 "Online Map Setup"
{
    Caption = 'Online Map Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Map Parameter Setup Code"; Code[10])
        {
            Caption = 'Map Parameter Setup Code';
            TableRelation = "Online Map Parameter Setup";
        }
        field(3; "Distance In"; Option)
        {
            Caption = 'Distance In';
            OptionCaption = 'Miles,Kilometers';
            OptionMembers = Miles,Kilometers;
        }
        field(4; Route; Option)
        {
            Caption = 'Route';
            OptionCaption = 'Quickest,Shortest';
            OptionMembers = Quickest,Shortest;
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

