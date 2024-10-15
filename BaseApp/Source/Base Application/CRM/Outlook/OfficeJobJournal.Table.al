namespace Microsoft.CRM.Outlook;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;

table 1615 "Office Job Journal"
{
    Caption = 'Office Job Journal';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
        }
        field(3; "Job Planning Line No."; Integer)
        {
            Caption = 'Job Planning Line No.';
        }
        field(4; "Job Journal Template Name"; Code[10])
        {
            Caption = 'Job Journal Template Name';
            TableRelation = "Job Journal Template".Name where("Page ID" = const(201),
                                                               Recurring = const(false));
        }
        field(5; "Job Journal Batch Name"; Code[10])
        {
            Caption = 'Job Journal Batch Name';
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Job Journal Template Name"));
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Job Planning Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Initialize(JobPlanningLine: Record "Job Planning Line")
    begin
        "Job No." := JobPlanningLine."Job No.";
        "Job Task No." := JobPlanningLine."Job Task No.";
        "Job Planning Line No." := JobPlanningLine."Line No.";
    end;
}

