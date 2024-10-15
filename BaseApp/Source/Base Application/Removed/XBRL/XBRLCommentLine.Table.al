// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

table 396 "XBRL Comment Line"
{
    Caption = 'XBRL Comment Line';
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
        field(3; "Comment Type"; Option)
        {
            Caption = 'Comment Type';
            OptionCaption = 'Information,Notes,Reference';
            OptionMembers = Information,Notes,Reference;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(6; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
        field(7; Date; Date)
        {
            Caption = 'Date';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Comment Type", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

