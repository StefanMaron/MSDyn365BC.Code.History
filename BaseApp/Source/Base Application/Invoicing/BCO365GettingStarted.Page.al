#if not CLEAN21
page 2300 "BC O365 Getting Started"
{
    Caption = 'Getting started';
    PageType = NavigatePage;
    SourceTable = "O365 Getting Started";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control3)
            {
                ShowCaption = false;
                Visible = CurrentPage;
                group(Control4)
                {
                    ShowCaption = false;
                    usercontrol(WelcomeWizard; "Microsoft.Dynamics.Nav.Client.WelcomeWizard")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;

                        trigger ControlAddInReady()
                        var
                            WelcomeToTitle: Text;
                            IntroductionDescription: Text;
                        begin
                            WelcomeToTitle := StrSubstNo(TitleTxt, PRODUCTNAME.Marketing());
                            IntroductionDescription := StrSubstNo(IntroDescTxt, PRODUCTNAME.Marketing());
                            CurrPage.WelcomeWizard.Initialize(
                              WelcomeToTitle, SubTitleTxt, '', IntroTxt, IntroductionDescription, SendInvoicesTxt, SendInvoicesDescTxt
                              , PaymentsTxt, PaymentsDescTxt, SettingsTxt, SettingsDescTxt, '',
                              '');
                        end;

                        trigger ErrorOccurred(error: Text; description: Text)
                        begin
                        end;

                        trigger Refresh()
                        begin
                        end;

                        trigger ThumbnailClicked(selection: Integer)
                        var
                            Video: Codeunit Video;
                        begin
                            case selection of
                                1:
                                    begin
                                        Session.LogMessage('000027X', IntroTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GettingStartedCategoryLbl);
                                        Video.Play('https://go.microsoft.com/fwlink/?linkid=2008767');
                                    end;
                                2:
                                    begin
                                        Session.LogMessage('000027Y', SendInvoicesTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GettingStartedCategoryLbl);
                                        Video.Play('https://go.microsoft.com/fwlink/?linkid=2008768');
                                    end;
                                3:
                                    begin
                                        Session.LogMessage('000027Z', PaymentsTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GettingStartedCategoryLbl);
                                        Video.Play('https://go.microsoft.com/fwlink/?linkid=2008680');
                                    end;
                                4:
                                    begin
                                        Session.LogMessage('0000280', SetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GettingStartedCategoryLbl);
                                        PAGE.RunModal(PAGE::"BC O365 My Settings");
                                    end;
                            end;
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateTestInvoice)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Try it out and send yourself a test invoice';
                InFooterBar = true;
                Promoted = true;
                RunObject = Page "BC O365 Sales Invoice";
                RunPageLink = "No." = CONST('TESTINVOICE');
                RunPageMode = Create;
                ToolTip = 'Create a new test invoice for the customer.';
                Visible = CreateTestInvoiceVisible;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action("Get Started")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Got it';
                InFooterBar = true;
                Promoted = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnClosePage()
    begin
        "Tour in Progress" := false;
        "Tour Completed" := true;
        Modify();
    end;

    trigger OnInit()
    begin
        SetRange("User ID", UserId);
        CreateTestInvoiceVisible := O365SetupMgmt.ShowCreateTestInvoice();
    end;

    trigger OnOpenPage()
    begin
        if not AlreadyShown() then
            MarkAsShown();

        CurrentPage := true;
    end;

    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
        TitleTxt: Label 'Welcome to %1', Comment = '%1 is the branding PRODUCTNAME.MARKETING string constant';
        SubTitleTxt: Label 'An easy-to-use online app for sending professional looking invoices to customers';
        IntroTxt: Label 'Introduction';
        IntroDescTxt: Label 'Get to know %1', Comment = '%1 is the branding PRODUCTNAME.MARKETING string constant';
        SendInvoicesTxt: Label 'Send invoices';
        SendInvoicesDescTxt: Label 'Send your first invoice to a customer';
        PaymentsTxt: Label 'Payments';
        PaymentsDescTxt: Label 'Get paid faster with online payments';
        SettingsTxt: Label 'Setup';
        SettingsDescTxt: Label 'Set up key information about your business';
        CurrentPage: Boolean;
        CreateTestInvoiceVisible: Boolean;
        GettingStartedCategoryLbl: Label 'AL Getting Started', Locked = true;
        IntroTelemetryTxt: Label 'Introduction video was played.', Locked = true;
        SendInvoicesTelemetryTxt: Label 'Send invoices video was played.', Locked = true;
        PaymentsTelemetryTxt: Label 'Payments video was played.', Locked = true;
        SetupTelemetryTxt: Label 'Setup was clicked from Getting Started.', Locked = true;
}
#endif
