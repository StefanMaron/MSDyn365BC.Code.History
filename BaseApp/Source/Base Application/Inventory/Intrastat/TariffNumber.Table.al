// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

table 260 "Tariff Number"
{
    Caption = 'Tariff Number';
    LookupPageID = "Tariff Numbers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
        }
        field(11760; "Statement Code"; Code[10])
        {
            Caption = 'Statement Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11761; "VAT Stat. Unit of Measure Code"; Code[10])
        {
            Caption = 'VAT Stat. Unit of Measure Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11762; "Allow Empty Unit of Meas.Code"; Boolean)
        {
            Caption = 'Allow Empty Unit of Meas.Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11763; "Statement Limit Code"; Code[10])
        {
            Caption = 'Statement Limit Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11792; "Full Name"; Text[250])
        {
            Caption = 'Full Name';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11793; "Full Name ENG"; Text[250])
        {
            Caption = 'Full Name ENG';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31060; "Supplem. Unit of Measure Code"; Code[10])
        {
            Caption = 'Supplem. Unit of Measure Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }
}

