page 9077 "O365 Invoicing Activities"
{
    Caption = 'Sales Activities';
    Description = 'ENU=Activites';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "O365 Sales Cue";

    layout
    {
        area(content)
        {
            cuegroup(Invoiced)
            {
                Caption = 'Invoiced';
                field("Invoiced YTD"; "Invoiced YTD")
                {
                    ApplicationArea = Invoicing;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Year to Date';
                    ToolTip = 'Specifies the total invoiced amount for this year.';

                    trigger OnDrillDown()
                    begin
                        ShowYearlySalesOverview;
                    end;
                }
                field("Invoiced CM"; "Invoiced CM")
                {
                    ApplicationArea = Invoicing;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'This Month';
                    ToolTip = 'Specifies the total amount invoiced for the current month.';

                    trigger OnDrillDown()
                    begin
                        ShowMonthlySalesOverview;
                    end;
                }
            }
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Sales Invoices Outstanding"; "Sales Invoices Outstanding")
                {
                    ApplicationArea = Invoicing;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Outstanding';
                    ToolTip = 'Specifies the total amount that has not yet been paid.';

                    trigger OnDrillDown()
                    begin
                        ShowInvoices(false);
                    end;
                }
                field("Sales Invoices Overdue"; "Sales Invoices Overdue")
                {
                    ApplicationArea = Invoicing;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Overdue';
                    ToolTip = 'Specifies the total amount that has not been paid and is after the due date.';

                    trigger OnDrillDown()
                    begin
                        ShowInvoices(true);
                    end;
                }
            }
            cuegroup(Ongoing)
            {
                Caption = 'Ongoing';
                field(NoOfQuotes; "No. of Quotes")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Estimates';
                    ToolTip = 'Specifies the number of estimates.';

                    trigger OnDrillDown()
                    begin
                        ShowQuotes;
                    end;
                }
                field(NoOfDrafts; "No. of Draft Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Invoice Drafts';
                    ToolTip = 'Specifies the number of draft invoices.';

                    trigger OnDrillDown()
                    begin
                        ShowDraftInvoices;
                    end;
                }
            }
            cuegroup("Invoice Now")
            {
                Caption = 'Invoice Now';
            }
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                trigger ResponseReceived(Status: Integer; Response: Text)
                var
                    SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
                begin
                    SatisfactionSurveyMgt.TryShowSurvey(Status, Response);
                end;

                trigger ControlAddInReady();
                begin
                    IsAddInReady := true;
                    CheckIfSurveyEnabled();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial;
    end;

    trigger OnInit()
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if EnvInfoProxy.IsInvoicing then
            CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");
    end;

    trigger OnOpenPage()
    begin
        OnOpenActivitiesPage(CurrencyFormatTxt);

        if PageNotifier.IsAvailable then begin
            PageNotifier := PageNotifier.Create;
            PageNotifier.NotifyPageReady;
        end;
    end;

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        CurrencyFormatTxt: Text;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;

    trigger PageNotifier::PageReady()
    begin
        IsPageReady := true;
        CheckIfSurveyEnabled();
    end;

    local procedure CheckIfSurveyEnabled()
    var
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
        CheckUrl: Text;
    begin
        if not IsAddInReady then
            exit;
        if not IsPageReady then
            exit;
        if not SatisfactionSurveyMgt.DeactivateSurvey() then
            exit;
        if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
            exit;
        CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
    end;
}

