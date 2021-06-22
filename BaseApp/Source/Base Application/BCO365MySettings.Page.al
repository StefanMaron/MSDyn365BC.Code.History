page 2399 "BC O365 My Settings"
{
    Caption = 'Settings';
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group("Business information")
            {
                Caption = 'Business information';
                group(Control22)
                {
                    InstructionalText = 'You can change the logo and your business information. This is shown on your invoices and estimates.';
                    ShowCaption = false;
                    part(Control20; "O365 Business Info Settings")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group(Language)
            {
                Caption = 'Language';
                Visible = LanguageVisible;
                group(Control34)
                {
                    InstructionalText = 'Select your preferred language. This will also apply to the documents you send. You must sign out and then sign in again for the change to take effect.';
                    ShowCaption = false;
                    part(Control30; "BC O365 Language Settings")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group("Email account")
            {
                Caption = 'Email account';
                part(GraphMailPage; "BC O365 Graph Mail Settings")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    UpdatePropagation = Both;
                    Visible = GraphMailVisible;
                }
                part(SmtpMailPage; "BC O365 Email Account Settings")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    UpdatePropagation = Both;
                    Visible = SmtpMailVisible;
                }
            }
            group("Email settings")
            {
                Caption = 'Email settings';
                group(Control55)
                {
                    InstructionalText = 'You can add email addresses to include your accountant or yourself for all sent invoices and estimates.';
                    ShowCaption = false;
                    part(Control50; "BC O365 Email Settings Part")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group("Invoice and estimate numbers")
            {
                Caption = 'Invoice and estimate numbers';
                group(Control66)
                {
                    InstructionalText = 'You can use the default way of numbering your invoices and estimates, or you can specify your own. If you change the number sequence, this will apply to new invoices and estimates.';
                    ShowCaption = false;
                    part(Control61; "BC O365 No. Series Settings")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                group(Control77)
                {
                    ShowCaption = false;
                    group(Control78)
                    {
                        ShowCaption = false;
                        part(Control70; "BC O365 Payments Settings")
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                        }
                    }
                    group("Online payments")
                    {
                        Caption = 'Online payments';
                        Visible = PaymentServicesVisible AND NOT IsDevice;
                        part(PaymentServicesSubpage; "BC O365 Payment Services")
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            UpdatePropagation = Both;
                        }
                    }
                }
            }
            group("VAT rates")
            {
                Caption = 'VAT rates';
                part(Control57; "BC O365 VAT Posting Setup List")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
            group(Services)
            {
                Caption = 'Services';
                group(Control101)
                {
                    InstructionalText = 'You can choose to use the VAT registration service that verifies the validity of your VAT registration number.';
                    ShowCaption = false;
                    part(Control110; "BC O365 Service Settings")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group("Intuit QuickBooks")
            {
                Caption = 'Intuit QuickBooks';
                Visible = QuickBooksVisible AND NOT IsDevice;
                group(Control155)
                {
                    Editable = false;
                    InstructionalText = 'You can connect Invoicing with QuickBooks, so you have access to data and contacts in both places.';
                    ShowCaption = false;
                    part(Control12; "BC O365 Quickbooks Settings")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
            }
            group(Control18)
            {
                Caption = 'Share';
                group(Share)
                {
                    Caption = '';
                    InstructionalText = 'Share an overview of sent invoices in an email.';
                    field(ExportInvoices; ExportInvoicesLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"O365 Export Invoices");
                        end;
                    }
                }
            }
            group("Mobile App")
            {
                Caption = 'Mobile App';
                Visible = NOT IsDevice;
                part(Control8; "BC O365 Mobile App")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetMailProviderVisibility;
    end;

    trigger OnOpenPage()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty;
        IsDevice := ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];

        QuickBooksVisible := O365SalesManagement.GetQuickBooksVisible;

        SetMailProviderVisibility;
        SetLanguageVisibility;
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        PaymentServicesVisible: Boolean;
        ExportInvoicesLbl: Label 'Send overview of invoices';
        QuickBooksVisible: Boolean;
        GraphMailVisible: Boolean;
        SmtpMailVisible: Boolean;
        LanguageVisible: Boolean;
        IsDevice: Boolean;

    local procedure SetMailProviderVisibility()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMail: Codeunit "Graph Mail";
    begin
        GraphMailVisible := false;
        if GraphMail.HasConfiguration then
            if GraphMail.IsEnabled then
                GraphMailVisible := true
            else
                if not O365SetupEmail.SMTPEmailIsSetUp then
                    if GraphMail.UserHasLicense then
                        GraphMailVisible := true;

        SmtpMailVisible := not GraphMailVisible;
    end;

    local procedure SetLanguageVisibility()
    var
        TempLanguage: Record "Windows Language" temporary;
        Language: Codeunit Language;
    begin
        Language.GetApplicationLanguages(TempLanguage);
        LanguageVisible := TempLanguage.Count > 1;
    end;
}

