// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 27049 "DIOT-Country/Region Data"
{
    Caption = 'DIOT Country/Region Data';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Country/Region Code"; Code[2])
        {
            Caption = 'Country/Region Code';
        }
        field(2; Nationality; Text[250])
        {
            Caption = 'Nationality';
        }
        field(3; "BC Country/Region Code"; Code[10])
        {
            Caption = 'BC Country/Region Code';
        }
    }

    keys
    {
        key(Key1; "Country/Region Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

