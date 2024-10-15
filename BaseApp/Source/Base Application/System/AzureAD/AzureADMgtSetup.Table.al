﻿namespace System.Azure.Identity;

#if not CLEAN21
using System.Integration.PowerBI;
#endif
using System.Reflection;

table 6303 "Azure AD Mgt. Setup"
{
    Caption = 'Microsoft Entra ID Mgt. Setup';

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
            ObsoleteReason = 'Disabling the Power BI integration through AzureADMgtSetup has been discontinued.';
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#endif
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
#if not CLEAN21
        Validate("PBI Service Mgt. Codeunit ID", CODEUNIT::"Power BI Service Mgt.");
#endif
    end;

    internal procedure IsSetupDifferentFromDefault(): Boolean
    begin
#if not CLEAN21
        exit(("Auth Flow Codeunit ID" <> CODEUNIT::"Azure AD Auth Flow") or
             ("Azure AD User Mgt. Codeunit ID" <> CODEUNIT::"Azure AD User Management") or
             ("PBI Service Mgt. Codeunit ID" <> CODEUNIT::"Power BI Service Mgt."));
#else
        exit(("Auth Flow Codeunit ID" <> CODEUNIT::"Azure AD Auth Flow") or
             ("Azure AD User Mgt. Codeunit ID" <> CODEUNIT::"Azure AD User Management"));
#endif
    end;
}

