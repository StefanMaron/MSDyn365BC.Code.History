table 31120 "EET Service Setup"
{
    Caption = 'EET Service Setup (Obsolete)';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;
        }
        field(10; "Sales Regime"; Option)
        {
            Caption = 'Sales Regime';
            OptionCaption = 'Regular,Simplified';
            OptionMembers = Regular,Simplified;
        }
        field(11; "Limit Response Time"; Integer)
        {
            Caption = 'Limit Response Time';
            InitValue = 2000;
            MinValue = 2000;
        }
        field(12; "Appointing VAT Reg. No."; Text[20])
        {
            Caption = 'Appointing VAT Reg. No.';
        }
        field(15; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
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
