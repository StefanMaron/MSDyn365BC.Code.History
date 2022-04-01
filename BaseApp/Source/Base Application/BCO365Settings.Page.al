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
                part(GraphMailPage; "BC O365 Graph Mail Settings")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                }
            }
#if not CLEAN20
            group(Control15)
            {
                ShowCaption = false;
                Visible = false;
                ObsoleteReason = 'Empty group';
                ObsoleteState = Pending;
                ObsoleteTag = '20.0';

                part(SmtpMailPage; "Email Scenarios FactBox") // Original part has been removed, Email Scenarios Factbox as dummy and part is not visible
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                    Visible = false;
                    ObsoleteReason = 'Part has been removed.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '20.0';
                }
            }
#endif
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
                ObsoleteState = Pending;
                ObsoleteReason = 'Quickbooks integration to Invoicing is discontinued.';
                ObsoleteTag = '17.0';
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

    trigger OnInit()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty;

        QuickBooksVisible := O365SalesManagement.GetQuickBooksVisible;
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        PaymentServicesVisible: Boolean;
        ExportInvoicesLbl: Label 'Send invoice overview';
        QuickBooksVisible: Boolean;
}

