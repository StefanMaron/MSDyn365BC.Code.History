page 7000041 "Cartera Source Cd. Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cartera Source Code Setup';
    PageType = Card;
    SourceTable = "Source Code Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cartera Journal"; "Cartera Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code related to the entries posted from the portfolio journal.';
                }
                field("Compress Bank Acc. Ledger"; "Compress Bank Acc. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Bank Acc. Ledger batch job.';
                }
                field("Compress Check Ledger"; "Compress Check Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Delete Check Ledger Entries batch job.';
                }
            }
        }
    }

    actions
    {
    }
}

