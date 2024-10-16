// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 15000200 "Payroll Integration Setup"
{
    Caption = 'Payroll Integration Setup';
    ReplicateData = false;
    ObsoleteReason = 'the feature converted into an extension';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[10])
        {
            Caption = 'Key';
            Editable = false;
        }
        field(10; "Payroll System"; Option)
        {
            Caption = 'Payroll System';
            OptionCaption = 'product 1,product 2';
            OptionMembers = "product 1","product 2";
        }
        field(11; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(13; "Import Department and Project"; Boolean)
        {
            Caption = 'Import Department and Project';
        }
        field(14; "Save Payroll File"; Boolean)
        {
            Caption = 'Save Payroll File';
        }
        field(20; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';

            trigger OnValidate()
            begin
                Validate("Journal Name", '');
            end;
        }
        field(21; "Journal Name"; Code[10])
        {
            Caption = 'Journal Name';
        }
        field(30; "Post to"; Option)
        {
            Caption = 'Post to';
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

