// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.Address;

table 10500 "Type of Supply"
{
    Caption = 'Type of Supply';
    LookupPageID = "Postcode Search";
    ObsoleteReason = 'Removed based on feedback.';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(10; Description; Text[30])
        {
            Caption = 'Description';
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}

