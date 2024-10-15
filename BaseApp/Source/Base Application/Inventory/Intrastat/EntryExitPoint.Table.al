﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

table 282 "Entry/Exit Point"
{
    Caption = 'Entry/Exit Point';
    DrillDownPageID = "Entry/Exit Points";
    LookupPageID = "Entry/Exit Points";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12100; "Group Code"; Code[10])
        {
            Caption = 'Group Code';
        }
        field(12101; "Reduce Statistical Value"; Boolean)
        {
            Caption = 'Reduce Statistical Value';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}