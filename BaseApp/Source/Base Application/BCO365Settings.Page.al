page 2315 "BC O365 Settings"
{
    Caption = 'Configure Invoicing';
    PageType = Card;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Control14)
            {
                ShowCaption = false;
                Visible = GraphMailVisible;
                part(GraphMailPage; "BC O365 Graph Mail Settings")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                }
            }
            group(Control15)
            {
                ShowCaption = false;
                Visible = SmtpMailVisible;
                part(SmtpMailPage; "BC O365 Email Account Settings")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                    Visible = SmtpMailVisible;
                }
            }
            part("Email settings"; "BC O365 Email Settings Part")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Email settings';
            }
            part("Invoice and estimate numbers"; "BC O365 No. Series Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Invoice and estimate numbers';
            }
            part(Payments; "BC O365 Payments Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Payments';
            }
            part("Payment instructions"; "BC O365 Payment Instr Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Payment instructions';
            }
            part("Payment services"; "BC O365 Payment Services")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Payment services';
                UpdatePropagation = Both;
                Visible = PaymentServicesVisible;
            }
            part("VAT rates"; "BC O365 VAT Posting Setup List")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'VAT rates';
            }
            part("VAT registration no."; "BC O365 Business Info Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'VAT registration no.';
            }
            part(Services; "BC O365 Service Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Services';
            }
            part("Intuit QuickBooks"; "BC O365 Quickbooks Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Intuit QuickBooks';
                Visible = QuickBooksVisible;
            }
            group(Control11)
            {
                ShowCaption = false;
                group(Share)
                {
                    Caption = 'Share';
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
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetMailProviderVisibility;
    end;

    trigger OnInit()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty;

        QuickBooksVisible := O365SalesManagement.GetQuickBooksVisible;

        SetMailProviderVisibility;
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        PaymentServicesVisible: Boolean;
        ExportInvoicesLbl: Label 'Send invoice overview';
        QuickBooksVisible: Boolean;
        GraphMailVisible: Boolean;
        SmtpMailVisible: Boolean;

    local procedure SetMailProviderVisibility()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMail: Codeunit "Graph Mail";
    begin
        SmtpMailVisible := (O365SetupEmail.SMTPEmailIsSetUp and (not GraphMail.IsEnabled)) or (not GraphMail.HasConfiguration);
        GraphMailVisible := not SmtpMailVisible;
    end;
}

