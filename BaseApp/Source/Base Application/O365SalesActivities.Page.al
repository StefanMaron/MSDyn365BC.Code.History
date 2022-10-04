#if not CLEAN21
page 9039 "O365 Sales Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "O365 Sales Cue";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            cuegroup(Invoiced)
            {
                Caption = 'Invoiced';
                CueGroupLayout = Wide;
                field("Invoiced YTD"; Rec."Invoiced YTD")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Sales this year';
                    ToolTip = 'Specifies the total invoiced amount for this year.';

                    trigger OnDrillDown()
                    begin
                        ShowYearlySalesOverview();
                    end;
                }
                field("Invoiced CM"; Rec."Invoiced CM")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Sales this month';
                    ToolTip = 'Specifies the total invoiced amount for this year.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ShowMonthlySalesOverview();
                    end;
                }
            }
            cuegroup(Payments)
            {
                Caption = 'Payments';
                CueGroupLayout = Wide;
                field("Sales Invoices Outstanding"; Rec."Sales Invoices Outstanding")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Outstanding amount';
                    ToolTip = 'Specifies the total amount that has not yet been paid.';

                    trigger OnDrillDown()
                    begin
                        ShowInvoices(false);
                    end;
                }
                field("Sales Invoices Overdue"; Rec."Sales Invoices Overdue")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'Overdue amount';
                    Style = Unfavorable;
                    StyleExpr = "Sales Invoices Overdue" > 0;
                    ToolTip = 'Specifies the total amount that has not been paid and is after the due date.';

                    trigger OnDrillDown()
                    begin
                        ShowInvoices(true);
                    end;
                }
            }
            cuegroup("Ongoing sales")
            {
                Caption = 'Ongoing sales';
                field(NoOfDrafts; "No. of Draft Invoices")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Draft invoices';
                    ToolTip = 'Specifies the number of draft invoices.';

                    trigger OnDrillDown()
                    begin
                        ShowDraftInvoices();
                    end;
                }
                field(NoOfQuotes; "No. of Quotes")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Estimates';
                    ToolTip = 'Specifies the number of estimates.';

                    trigger OnDrillDown()
                    begin
                        ShowQuotes();
                    end;
                }
                field(NoOfUnpaidInvoices; NumberOfUnpaidInvoices)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Unpaid invoices';
                    ToolTip = 'Specifies the number of invoices that have been sent but not paid yet.';

                    trigger OnDrillDown()
                    begin
                        ShowUnpaidInvoices();
                    end;
                }
            }
            cuegroup(New)
            {
                Caption = 'New';

                actions
                {
                    action("New invoice")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'New invoice';
                        Image = TileNew;
                        RunObject = Page "BC O365 Sales Invoice";
                        RunPageMode = Create;
                        ToolTip = 'Create a new invoice for the customer.';
                    }
                    action("New estimate")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'New estimate';
                        Image = TileNew;
                        RunObject = Page "BC O365 Sales Quote";
                        RunPageMode = Create;
                        ToolTip = 'Create a new estimate for the customer.';
                    }
                }
            }
            cuegroup("Get started")
            {
                Caption = 'Get started';
                Visible = GettingStartedGroupVisible;

                actions
                {
                    action(CreateTestInvoice)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Send a test invoice';
                        Image = TileNew;
                        RunObject = Page "BC O365 Sales Invoice";
                        RunPageLink = "No." = CONST('TESTINVOICE');
                        RunPageMode = Create;
                        ToolTip = 'Create a new test invoice.';
                        Visible = CreateTestInvoiceVisible;

                        trigger OnAction()
                        begin
                            CurrPage.Update();
                        end;
                    }
                    action(ReplayGettingStarted)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Play Getting Started';
                        Image = TileVideo;
                        ToolTip = 'Show the Getting Started guide.';
                        Visible = ReplayGettingStartedVisible;

                        trigger OnAction()
                        var
                            O365GettingStarted: Record "O365 Getting Started";
                        begin
                            if O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then begin
                                O365GettingStarted."Tour in Progress" := false;
                                O365GettingStarted."Current Page" := 1;
                                O365GettingStarted.Modify();
                                Commit();
                            end;

                            if O365SetupMgmt.GettingStartedSupportedForInvoicing() then
                                PAGE.Run(PAGE::"BC O365 Getting Started");
                        end;
                    }
                    action(SetupBusinessInfo)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Set up your information';
                        Image = TileSettings;
                        ToolTip = 'Set up your key business information';
                        Visible = SetupBusinessInfoVisible;

                        trigger OnAction()
                        begin
                            PAGE.RunModal(PAGE::"BC O365 My Settings");
                        end;
                    }
                    action(SetupPayments)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Set up online payments';
                        Image = TileCurrency;
                        ToolTip = 'Set up your online payments service.';
                        Visible = PaymentServicesVisible;

                        trigger OnAction()
                        begin
                            PAGE.Run(PAGE::"BC O365 Payment Services Card");
                        end;
                    }
                }
            }
            cuegroup(WantMoreGrp)
            {
                Caption = 'Want more?';
                Visible = WantMoreGroupVisible;

                actions
                {
                    action(TryBusinessCentral)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Try Business Central';
                        Image = TileReport;
                        RunObject = Page "O365 To D365 Trial";
                        RunPageMode = View;
                        ToolTip = 'Explore Dynamics 365 Business Central and see what it can do for your business.';

                        trigger OnAction()
                        begin
                            Session.LogMessage('000081X', InvToBusinessCentralTrialTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
                        end;
                    }
                }
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
    begin
        O365DocumentSendMgt.ShowRoleCenterEmailNotification(true);
        NumberOfUnpaidInvoices := GetNumberOfUnpaidInvoices();
        CreateTestInvoiceVisible := O365SetupMgmt.ShowCreateTestInvoice();
        GettingStartedGroupVisible :=
          CreateTestInvoiceVisible or ReplayGettingStartedVisible or PaymentServicesVisible or SetupBusinessInfoVisible;
    end;

    trigger OnInit()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        IsDevice := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty() and not IsDevice;
        ReplayGettingStartedVisible := O365SetupMgmt.GettingStartedSupportedForInvoicing();
        WantMoreGroupVisible := O365SetupMgmt.GetBusinessCentralTrialVisibility();
        SetupBusinessInfoVisible := not IsDevice;
    end;

    trigger OnOpenPage()
    begin
        OnOpenActivitiesPage(CurrencyFormatTxt);
        SetRange("User ID Filter", UserId);
        PreparePageNotifier();
        O365DocumentSendMgt.ShowRoleCenterEmailNotification(false);
    end;

    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
        ClientTypeManagement: Codeunit "Client Type Management";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        CurrencyFormatTxt: Text;
        CreateTestInvoiceVisible: Boolean;
        ReplayGettingStartedVisible: Boolean;
        PaymentServicesVisible: Boolean;
        NumberOfUnpaidInvoices: Integer;
        IsDevice: Boolean;
        SetupBusinessInfoVisible: Boolean;
        GettingStartedGroupVisible: Boolean;
        WantMoreGroupVisible: Boolean;
        InvToBusinessCentralTrialTelemetryTxt: Label 'User clicked the tile to try Business Central from Invoicing.', Locked = true;
        InvToBusinessCentralCategoryLbl: Label 'AL Invoicing To Business Central', Locked = true;
        HideSatisfactionSurvey: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;

    local procedure PreparePageNotifier()
    begin
        if not PageNotifier.IsAvailable() then
            exit;
        PageNotifier := PageNotifier.Create();
        PageNotifier.NotifyPageReady();
    end;

    trigger PageNotifier::PageReady()
    begin
        IsPageReady := true;
        if O365SetupMgmt.WizardShouldBeOpenedForInvoicing then begin
            HideSatisfactionSurvey := true;
            Commit(); // COMMIT is required for opening page without write transcation error.
            PAGE.RunModal(PAGE::"BC O365 Getting Started");
        end;
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
        if HideSatisfactionSurvey then
            exit;
        if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
            exit;
        CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
    end;
}
#endif
