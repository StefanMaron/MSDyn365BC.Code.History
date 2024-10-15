#if not CLEAN17
page 11761 "Electronically Govern. Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Communication Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Electronically Govern. Setup";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group("Payer Uncertainty")
            {
                Caption = 'Payer Uncertainty';
                field(UncertaintyPayerWebService; UncertaintyPayerWebService)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies web service for control uncertainty payers';
                }
                field("Public Bank Acc.Chck.Star.Date"; "Public Bank Acc.Chck.Star.Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the first date for checking public bank account of uncertainty payer.';
                }
                field("Public Bank Acc.Check Limit"; "Public Bank Acc.Check Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the limit of purchase document for checking public bank account of uncertainty payer.';
                }
                field("Unc.Payer Request Record Limit"; "Unc.Payer Request Record Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the record limit in one batch for checking uncertainty payer.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
        }
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
#endif