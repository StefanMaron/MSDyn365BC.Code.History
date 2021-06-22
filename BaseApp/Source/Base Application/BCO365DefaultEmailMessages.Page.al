page 2370 "BC O365 Default Email Messages"
{
    Caption = 'Default Email Messages';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                group(Control3)
                {
                    InstructionalText = 'You can change the default email messages for your documents. You will be able to review and edit the message for every invoice and estimate you send.';
                    ShowCaption = false;
                    group("Default Invoice Email Message")
                    {
                        Caption = 'Default Invoice Email Message';
                        field(DefaultInvoiceEmailMessage; InvoiceEmailMessage)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Default Invoice Email Message';
                            MultiLine = true;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                if InvoiceEmailMessage = '' then
                                    InvoiceEmailMessage := ' ';
                            end;
                        }
                    }
                    group("Default Estimate Email Message")
                    {
                        Caption = 'Default Estimate Email Message';
                        field(DefaultQuoteEmailMessage; QuoteEmailMessage)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Default Estimate Email Message';
                            MultiLine = true;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                if QuoteEmailMessage = '' then
                                    QuoteEmailMessage := ' ';
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        InvoiceEmailMessage := O365DefaultEmailMsg.GetMessage(O365DefaultEmailMsg."Document Type"::Invoice);
        QuoteEmailMessage := O365DefaultEmailMsg.GetMessage(O365DefaultEmailMsg."Document Type"::Quote);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [ACTION::LookupOK, ACTION::OK]) then
            exit;

        if O365DefaultEmailMsg.Get(O365DefaultEmailMsg."Document Type"::Invoice) then
            O365DefaultEmailMsg.SetMessage(InvoiceEmailMessage);

        if O365DefaultEmailMsg.Get(O365DefaultEmailMsg."Document Type"::Quote) then
            O365DefaultEmailMsg.SetMessage(QuoteEmailMessage);
    end;

    var
        O365DefaultEmailMsg: Record "O365 Default Email Message";
        InvoiceEmailMessage: Text;
        QuoteEmailMessage: Text;
}

