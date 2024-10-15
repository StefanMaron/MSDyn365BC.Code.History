// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

using System.Globalization;

table 401 "XBRL Taxonomy Label"
{
    Caption = 'XBRL Taxonomy Label';
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "XBRL Taxonomy Name"; Code[20])
        {
            Caption = 'XBRL Taxonomy Name';
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "XBRL Taxonomy Line No."; Integer)
        {
            Caption = 'XBRL Taxonomy Line No.';
            TableRelation = "XBRL Taxonomy Line"."Line No." where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"));
        }
        field(3; "XML Language Identifier"; Text[10])
        {
            Caption = 'XML Language Identifier';
        }
        field(4; "Windows Language ID"; Integer)
        {
            Caption = 'Windows Language ID';
        }
        field(5; "Windows Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Windows Language ID")));
            Caption = 'Windows Language Name';
            FieldClass = FlowField;
        }
        field(6; Label; Text[250])
        {
            Caption = 'Label';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "XML Language Identifier")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

