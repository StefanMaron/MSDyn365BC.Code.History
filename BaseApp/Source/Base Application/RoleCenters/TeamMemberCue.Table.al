// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Projects.TimeSheet;

table 9042 "Team Member Cue"
{
    Caption = 'Team Member Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Open Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Open Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Time Sheets In progress';
            FieldClass = FlowField;
        }
        field(3; "Submitted Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Submitted Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Submitted Time Sheets';
            FieldClass = FlowField;
        }
        field(4; "Rejected Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Rejected Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Rejected Time Sheets';
            FieldClass = FlowField;
        }
        field(5; "Approved Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Approved Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Approved Time Sheets';
            FieldClass = FlowField;
        }
        field(7; "Time Sheets to Approve"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Approver User ID" = field("Approve ID Filter"),
                                                           "Submitted Exists" = const(true)));
            Caption = 'Time Sheets to Approve';
            FieldClass = FlowField;
        }
        field(9; "New Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Lines Exist" = filter(= false),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'New Time Sheets';
            FieldClass = FlowField;
        }
        field(28; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Approve ID Filter"; Code[50])
        {
            Caption = 'Approve ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

