// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

table 398 "XBRL Rollup Line"
{
    Caption = 'XBRL Rollup Line';
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
        field(4; "From XBRL Taxonomy Line No."; Integer)
        {
            Caption = 'From XBRL Taxonomy Line No.';
            TableRelation = "XBRL Taxonomy Line"."Line No." where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"));
        }
        field(5; "From XBRL Taxonomy Line Name"; Text[250])
        {
            CalcFormula = lookup("XBRL Taxonomy Line".Name where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                                  "Line No." = field("From XBRL Taxonomy Line No.")));
            Caption = 'From XBRL Taxonomy Line Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "From XBRL Taxonomy Line Label"; Text[250])
        {
            CalcFormula = lookup("XBRL Taxonomy Label".Label where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                                    "XBRL Taxonomy Line No." = field("From XBRL Taxonomy Line No."),
                                                                    "XML Language Identifier" = field("Label Language Filter")));
            Caption = 'From XBRL Taxonomy Line Label';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 0;
            MaxValue = 1;
            MinValue = -1;
        }
        field(9; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "From XBRL Taxonomy Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

