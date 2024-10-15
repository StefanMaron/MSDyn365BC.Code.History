page 11308 "Electronic Banking Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Banking Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Electronic Banking Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Summarize Gen. Jnl. Lines"; "Summarize Gen. Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to summarize the payment journal lines by vendor, when you transfer the electronic banking journal lines.';
                }
                field("Cut off Payment Message Texts"; "Cut off Payment Message Texts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the payment message text to be truncated.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

