// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 5490 "Onboarding Signal"
{
    Access = Internal;
    Extensible = false;
    DataClassification = OrganizationIdentifiableInformation;
    DataPerCompany = false;
    ReplicateData = false;
    Scope = Cloud;
    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'Used as primary key';
            AutoIncrement = true;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(3; "Onboarding Completed"; Boolean)
        {
            Caption = 'Onboarding Completed';
            Description = 'Whether the onboarding criteria has been met for this entry';
        }
        field(4; "Onboarding Signal Type"; Enum "Onboarding Signal Type")
        {
            Caption = 'Onboarding Signal Type';
        }
    }

    keys
    {
        key(key1; "No.")
        {
        }
    }
}