// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

table 5481 "Account Entity Setup"
{
    Caption = 'Account Entity Setup';
    ObsoleteReason = 'Became obsolete after refactoring of the NAV APIs.';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Show Balance"; Boolean)
        {
            Caption = 'Show Balance';
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

    procedure SafeGet()
    begin
        if not Get() then
            Insert();
    end;
}

