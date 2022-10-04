table 5061 "Rlshp. Mgt. Comment Line"
{
    Caption = 'Rlshp. Mgt. Comment Line';
    DrillDownPageID = "Rlshp. Mgt. Comment List";
    LookupPageID = "Rlshp. Mgt. Comment List";

    fields
    {
        field(1; "Table Name"; Enum "Rlshp. Mgt. Comment Line Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Table Name" = CONST(Contact)) Contact
            ELSE
            IF ("Table Name" = CONST(Campaign)) Campaign
            ELSE
            IF ("Table Name" = CONST("To-do")) "To-do"
            ELSE
            IF ("Table Name" = CONST("Web Source")) "Web Source"
            ELSE
            IF ("Table Name" = CONST("Sales Cycle")) "Sales Cycle"
            ELSE
            IF ("Table Name" = CONST("Sales Cycle Stage")) "Sales Cycle Stage"
            ELSE
            IF ("Table Name" = CONST(Opportunity)) Opportunity;
        }
        field(3; "Sub No."; Integer)
        {
            Caption = 'Sub No.';
            TableRelation = IF ("Table Name" = CONST("Sales Cycle Stage")) "Sales Cycle Stage".Stage WHERE("Sales Cycle Code" = FIELD("No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(8; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Sub No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    procedure SetUpNewLine()
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        RlshpMgtCommentLine.SetRange("Table Name", "Table Name");
        RlshpMgtCommentLine.SetRange("No.", "No.");
        RlshpMgtCommentLine.SetRange("Sub No.", "Sub No.");
        RlshpMgtCommentLine.SetRange(Date, WorkDate());
        if not RlshpMgtCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, RlshpMgtCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var RlshpMgtCommentLineRec: Record "Rlshp. Mgt. Comment Line"; var RlshpMgtCommentLineFilter: Record "Rlshp. Mgt. Comment Line")
    begin
    end;
}

