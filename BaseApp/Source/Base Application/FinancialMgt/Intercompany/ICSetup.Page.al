#if not CLEAN20
page 621 "IC Setup"
{
    Caption = 'Intercompany Setup';
    PageType = StandardDialog;
    SourceTable = "Company Information";
    ObsoleteReason = 'Replaced by "Intercompany Setup" page.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group("Current Company")
            {
                field("IC Partner Code";
                "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Partner Code';
                    ToolTip = 'Specifies the IC partner code of your company. This is the IC partner code that your IC partners will use to send their transactions to.';
                }
                field("Auto. Send Transactions"; Rec."Auto. Send Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Auto. Send Transactions';
                    ToolTip = 'Specifies that as soon as transactions arrive in the intercompany outbox, they will be sent to the intercompany partner.';
                }
                field(OpenNewICSetupPageTxt; OpenNewICSetupPageTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Run new Intercompany Setup page.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.Update(true);
                        Page.Run(Page::"Intercompany Setup");
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        ICAutoAcceptFeatureMgt: Codeunit "IC Auto Accept Feature Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        if ICAutoAcceptFeatureMgt.IsICAutoAcceptTransactionEnabled() then begin
            Page.Run(Page::"Intercompany Setup");
            Error('');
        end;

        FeatureTelemetry.LogUptake('0000IIZ', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        OpenNewICSetupPageTxt: Label 'Open new Intercompany Setup page';
}
#endif

