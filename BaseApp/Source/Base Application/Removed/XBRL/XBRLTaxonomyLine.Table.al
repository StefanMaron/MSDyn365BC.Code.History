// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;

table 395 "XBRL Taxonomy Line"
{
    Caption = 'XBRL Taxonomy Line';
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
            NotBlank = true;
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Name; Text[220])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(4; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5; Label; Text[250])
        {
            CalcFormula = lookup("XBRL Taxonomy Label".Label where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                                    "XBRL Taxonomy Line No." = field("Line No."),
                                                                    "XML Language Identifier" = field("Label Language Filter")));
            Caption = 'Label';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Not Applicable,Rollup,Constant,General Ledger,Notes,Description,Tuple';
            OptionMembers = "Not Applicable",Rollup,Constant,"General Ledger",Notes,Description,Tuple;
        }
        field(7; "Constant Amount"; Decimal)
        {
            Caption = 'Constant Amount';
            DecimalPlaces = 0 : 5;
        }
        field(8; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(9; "XBRL Item Type"; Text[250])
        {
            Caption = 'XBRL Item Type';
        }
        field(10; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(11; Information; Boolean)
        {
            CalcFormula = exist("XBRL Comment Line" where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = field("Line No."),
                                                           "Comment Type" = const(Information)));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; Rollup; Boolean)
        {
            CalcFormula = exist("XBRL Rollup Line" where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                          "XBRL Taxonomy Line No." = field("Line No.")));
            Caption = 'Rollup';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "G/L Map Lines"; Boolean)
        {
            CalcFormula = exist("XBRL G/L Map Line" where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = field("Line No.")));
            Caption = 'G/L Map Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; Notes; Boolean)
        {
            CalcFormula = exist("XBRL Comment Line" where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = field("Line No."),
                                                           "Comment Type" = const(Notes)));
            Caption = 'Notes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(16; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(17; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(18; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(19; "XBRL Schema Line No."; Integer)
        {
            Caption = 'XBRL Schema Line No.';
            TableRelation = "XBRL Schema"."Line No." where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"));
        }
        field(20; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Presentation Order"; Text[100])
        {
            Caption = 'Presentation Order';
        }
        field(22; "Presentation Order No."; Integer)
        {
            Caption = 'Presentation Order No.';
        }
        field(23; Reference; Boolean)
        {
            CalcFormula = exist("XBRL Comment Line" where("XBRL Taxonomy Name" = field("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = field("Line No."),
                                                           "Comment Type" = const(Reference)));
            Caption = 'Reference';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Element ID"; Text[220])
        {
            Caption = 'Element ID';
        }
        field(25; "Numeric Context Period Type"; Option)
        {
            Caption = 'Numeric Context Period Type';
            OptionCaption = ',Instant,Duration';
            OptionMembers = ,Instant,Duration;
        }
        field(26; "Presentation Linkbase Line No."; Integer)
        {
            Caption = 'Presentation Linkbase Line No.';
        }
        field(27; "Type Description Element"; Boolean)
        {
            Caption = 'Type Description Element';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
        key(Key3; "XBRL Taxonomy Name", "Presentation Order")
        {
        }
        key(Key4; "Parent Line No.")
        {
        }
        key(Key5; "XBRL Taxonomy Name", "Element ID")
        {
        }
    }

    fieldgroups
    {
    }
}

