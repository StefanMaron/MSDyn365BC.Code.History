﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

table 1020 "Job Usage Link"
{
    Caption = 'Job Usage Link';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."),
                                                                  "Job Task No." = field("Job Task No."));
        }
        field(4; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Line No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Create(JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
        if Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.", JobLedgerEntry."Entry No.") then
            exit;

        Validate("Job No.", JobPlanningLine."Job No.");
        Validate("Job Task No.", JobPlanningLine."Job Task No.");
        Validate("Line No.", JobPlanningLine."Line No.");
        Validate("Entry No.", JobLedgerEntry."Entry No.");
        Insert(true);
    end;
}

