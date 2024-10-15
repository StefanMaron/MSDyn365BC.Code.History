#if not CLEAN22
table 13400 "Intrastat - File Setup"
{
    Caption = 'Intrastat - File Setup';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Custom Code"; Text[2])
        {
            Caption = 'Custom Code';
        }
        field(3; "Company Serial No."; Text[3])
        {
            Caption = 'Company Serial No.';
        }
        field(4; "Last Transfer Date"; Date)
        {
            Caption = 'Last Transfer Date';
            Editable = false;
        }
        field(5; "File No."; Code[3])
        {
            Caption = 'File No.';
            Editable = false;
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
#endif