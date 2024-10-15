// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using System.Reflection;

table 8451 "Intrastat Checklist Setup"
{
    Caption = 'Intrastat Checklist Setup';
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Replaced by Advanced Intrastat Checklist';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';

            trigger OnValidate()
            var
                "Field": Record "Field";
            begin
                Field.Get(DATABASE::"Intrastat Jnl. Line", "Field No.");
                "Field Name" := Field.FieldName;
            end;
        }
        field(2; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
    }

    keys
    {
        key(Key1; "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure LookupFieldName()
    var
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.SetRange(TableNo, DATABASE::"Intrastat Jnl. Line");
        Field.SetFilter("No.", '<>1&<>2&<>3');
        Field.SetRange(Class, Field.Class::Normal);
        if FieldSelection.Open(Field) then
            Validate("Field No.", Field."No.");
    end;
}

