page 621 "IC Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Setup';
    PageType = StandardDialog;
    SourceTable = "Company Information";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group("Current Company")
            {
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Partner Code';
                    ToolTip = 'Specifies the IC partner code of your company. This is the IC partner code that your IC partners will use to send their transactions to.';
                }
                field("Auto. Send Transactions"; "Auto. Send Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Auto. Send Transactions';
                    ToolTip = 'Specifies that as soon as transactions arrive in the intercompany outbox, they will be sent to the intercompany partner.';
                }
            }
        }
    }

    actions
    {
    }
}

