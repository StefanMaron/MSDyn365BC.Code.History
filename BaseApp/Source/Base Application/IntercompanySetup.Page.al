page 653 "Intercompany Setup"
{
    Caption = 'Intercompany Setup';
    PageType = Card;
    ApplicationArea = Intercompany;
    UsageCategory = Administration;
    SourceTable = "IC Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Partner Code';
                    ToolTip = 'Specifies your company''s intercompany partner code.';
                }
                field("IC Inbox Type"; "IC Inbox Type")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Inbox Type';
                    ToolTip = 'Specifies what type of intercompany inbox you have, either File Location or Database.';
                }
                field("IC Inbox Details"; "IC Inbox Details")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Inbox Details';
                    ToolTip = 'Specifies details about the location of your intercompany inbox, which can transfer intercompany transactions into your company.';
                }
                field("Auto. Send Transactions"; "Auto. Send Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Auto. Send Transactions';
                    ToolTip = 'Specifies that as soon as transactions arrive in the intercompany outbox, they will be sent to the intercompany partner.';
                }
                field("Default IC Gen. Jnl. Template"; "Default IC Gen. Jnl. Template")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Default IC Gen. Jnl. Template';
                    ToolTip = 'Specifies journal template that wiil be used to create journal line as soon as transactions arrive in the intercompany inbox.';
                }
                field("Default IC Gen. Jnl. Batch"; "Default IC Gen. Jnl. Batch")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Default IC Gen. Jnl. Batch';
                    ToolTip = 'Specifies journal batch that wiil be used to create journal line as soon as transactions arrive in the intercompany inbox.';
                }
            }
        }
    }
#if not CLEAN20
    trigger OnInit()
    var
        ICAutoAcceptFeatureMgt: Codeunit "IC Auto Accept Feature Mgt.";
    begin
        ICAutoAcceptFeatureMgt.FailIfFeatureDisabled();
    end;
#endif

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}