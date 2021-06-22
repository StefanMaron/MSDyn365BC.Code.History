table 97 "Comment Line"
{
    Caption = 'Comment Line';
    DrillDownPageID = "Comment List";
    LookupPageID = "Comment List";

    fields
    {
        field(1; "Table Name"; Enum "Comment Line Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine.SetRange("Table Name", "Table Name");
        CommentLine.SetRange("No.", "No.");
        CommentLine.SetRange(Date, WorkDate);
        if not CommentLine.FindFirst then
            Date := WorkDate;

        OnAfterSetUpNewLine(Rec, CommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var CommentLineRec: Record "Comment Line"; var CommentLineFilter: Record "Comment Line")
    begin
    end;
}

