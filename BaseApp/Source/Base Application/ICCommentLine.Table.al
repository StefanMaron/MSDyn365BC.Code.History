table 424 "IC Comment Line"
{
    Caption = 'IC Comment Line';

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'IC Inbox Transaction,IC Outbox Transaction,Handled IC Inbox Transaction,Handled IC Outbox Transaction';
            OptionMembers = "IC Inbox Transaction","IC Outbox Transaction","Handled IC Inbox Transaction","Handled IC Outbox Transaction";
        }
        field(2; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(3; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
        }
    }

    keys
    {
        key(Key1; "Table Name", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        ICCommentLine: Record "IC Comment Line";
    begin
        ICCommentLine.SetRange("Table Name", "Table Name");
        ICCommentLine.SetRange("Transaction No.", "Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", "IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", "Transaction Source");
        ICCommentLine.SetRange(Date, WorkDate());
        if not ICCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ICCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ICCommentLineRec: Record "IC Comment Line"; var ICCommentLineFilter: Record "IC Comment Line")
    begin
    end;
}

