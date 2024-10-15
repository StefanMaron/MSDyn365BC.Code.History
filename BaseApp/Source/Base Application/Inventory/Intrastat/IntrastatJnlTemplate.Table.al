// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

table 261 "Intrastat Jnl. Template"
{
    Caption = 'Intrastat Jnl. Template';
    ReplicateData = true;
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Checklist Report ID"; Integer)
        {
            Caption = 'Checklist Report ID';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(15; "Checklist Report Caption"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(16; "Page Caption"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(31060; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

