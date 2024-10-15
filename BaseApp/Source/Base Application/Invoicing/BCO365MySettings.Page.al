#if not CLEAN21
page 2399 "BC O365 My Settings"
{
    Caption = 'Settings';
    RefreshOnActivate = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
                    }
                }
            }
            group("Email account")
            {
                Caption = 'Email account';
                part(GraphMailPage; "BC O365 Graph Mail Settings")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    UpdatePropagation = Both;
                    Visible = GraphMailVisible;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                            ApplicationArea = Invoicing, Basic, Suite;
                        }
                    }
                    group("Online payments")
                    {
                        Caption = 'Online payments';
                        Visible = PaymentServicesVisible AND NOT IsDevice;
                        part(PaymentServicesSubpage; "BC O365 Payment Services")
                        {
                            ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
                    }
                }
            }
            group("Intuit QuickBooks")
            {
                Caption = 'Intuit QuickBooks';
                Visible = QuickBooksVisible AND NOT IsDevice;
                ObsoleteState = Pending;
                ObsoleteReason = 'Quickbooks integration to Invoicing is discontinued.';
                ObsoleteTag = '17.0';

                group(Control155)
                {
                    Editable = false;
                    InstructionalText = 'You can connect Invoicing with QuickBooks, so you have access to data and contacts in both places.';
                    ShowCaption = false;
                    part(Control12; "BC O365 Quickbooks Settings")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetMailProviderVisibility();
    end;

    trigger OnOpenPage()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty();
        IsDevice := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];

        QuickBooksVisible := O365SalesManagement.GetQuickBooksVisible();

        SetMailProviderVisibility();
        SetLanguageVisibility();
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        PaymentServicesVisible: Boolean;
        ExportInvoicesLbl: Label 'Send overview of invoices';
        QuickBooksVisible: Boolean;
        GraphMailVisible: Boolean;
        LanguageVisible: Boolean;
        IsDevice: Boolean;

    local procedure SetMailProviderVisibility()
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        GraphMailVisible := false;
        if GraphMail.HasConfiguration() then
            if GraphMail.IsEnabled() or GraphMail.UserHasLicense() then
                GraphMailVisible := true;
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
#endif
