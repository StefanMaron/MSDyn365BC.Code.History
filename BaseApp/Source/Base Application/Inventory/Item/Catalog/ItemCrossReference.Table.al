// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

table 5717 "Item Cross Reference"
{
    Caption = 'Item Cross Reference';
    ObsoleteReason = 'Replaced by ItemReference table as part of Item Reference feature.';
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(3; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
        }
        field(4; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";
        }
        field(5; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
        }
        field(6; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Discontinue Bar Code"; Boolean)
        {
            Caption = 'Discontinue Bar Code';

        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference Type No.", "Cross-Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Cross-Reference No.")
        {
        }
        key(Key3; "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Discontinue Bar Code")
        {
        }
        key(Key4; "Cross-Reference Type", "Cross-Reference No.")
        {
        }
        key(Key5; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference No.", "Discontinue Bar Code")
        {
        }
        key(Key6; "Cross-Reference Type", "Cross-Reference Type No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Cross-Reference Type", "Cross-Reference Type No.", "Cross-Reference No.", Description)
        {
        }
    }
}
