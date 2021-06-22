table 6303 "Azure AD Mgt. Setup"
{
    Caption = 'Azure AD Mgt. Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Auth Flow Codeunit ID"; Integer)
        {
            Caption = 'Auth Flow Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(3; "Azure AD User Mgt. Codeunit ID"; Integer)
        {
            Caption = 'Azure AD User Mgt. Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(4; "PBI Service Mgt. Codeunit ID"; Integer)
        {
            Caption = 'PBI Service Mgt. Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
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

    procedure ResetToDefault()
    begin
        Validate("Auth Flow Codeunit ID", CODEUNIT::"Azure AD Auth Flow");
        Validate("Azure AD User Mgt. Codeunit ID", CODEUNIT::"Azure AD User Management");
        Validate("PBI Service Mgt. Codeunit ID", CODEUNIT::"Power BI Service Mgt.");
    end;
}

