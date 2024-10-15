table 5515 "Integration Management Setup"
{
    Caption = 'Integration Management Setup';
    ObsoleteState = Removed;
    ObsoleteReason = 'The table will be removed with Integration Management. Refactor to use systemID, systemLastModifiedAt and other system fields.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
        }
        field(2; "Table Caption"; Text[249])
        {
            Caption = 'Table Caption';
            Editable = false;
        }
        field(3; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(4; "Completed"; Boolean)
        {
            Caption = 'Completed';
            Editable = false;
        }
        field(5; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
        }
        field(6; "Batch Size"; Integer)
        {
            Caption = 'Batch Size';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Completed", "Enabled")
        {
        }
    }
}

