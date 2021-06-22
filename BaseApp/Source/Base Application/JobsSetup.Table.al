table 315 "Jobs Setup"
{
    Caption = 'Jobs Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Job Nos."; Code[20])
        {
            Caption = 'Job Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Apply Usage Link by Default"; Boolean)
        {
            Caption = 'Apply Usage Link by Default';
            InitValue = true;
        }
        field(4; "Default WIP Method"; Code[20])
        {
            Caption = 'Default WIP Method';
            TableRelation = "Job WIP Method".Code;
        }
        field(5; "Default Job Posting Group"; Code[20])
        {
            Caption = 'Default Job Posting Group';
            TableRelation = "Job Posting Group".Code;
        }
        field(6; "Default WIP Posting Method"; Option)
        {
            Caption = 'Default WIP Posting Method';
            OptionCaption = 'Per Job,Per Job Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(7; "Allow Sched/Contract Lines Def"; Boolean)
        {
            Caption = 'Allow Sched/Contract Lines Def';
            InitValue = true;
        }
        field(31; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(40; "Job WIP Nos."; Code[20])
        {
            Caption = 'Job WIP Nos.';
            TableRelation = "No. Series";
        }
        field(1001; "Automatic Update Job Item Cost"; Boolean)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Automatic Update Job Item Cost';
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

