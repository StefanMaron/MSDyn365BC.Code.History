#if CLEAN19
page 1402 "Purchase No. Series Setup"
{
    Caption = 'Purchase No. Series Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Purchases & Payables Setup";

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Quote Nos."; "Quote Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase quotes. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = QuoteNosVisible;
                }
                field("Blanket Order Nos."; "Blanket Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket purchase orders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = BlanketOrderNosVisible;
                }
                field("Order Nos."; "Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase orders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = OrderNosVisible;
                }
                field("Return Order Nos."; "Return Order Nos.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number series that is used to assign numbers to new purchase return orders.';
                    Visible = ReturnOrderNosVisible;
                }
                field("Invoice Nos."; "Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase invoices. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = InvoiceNosVisible;
                }
                field("Credit Memo Nos."; "Credit Memo Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase credit memos. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = CreditMemoNosVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchases & Payables Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Purchases & Payables Setup";
                ToolTip = 'Define your general policies for purchase invoicing and returns, such as whether to require vendor invoice numbers and how to post purchase discounts. Set up your number series for creating vendors and different purchase documents.';
            }
        }
    }

    var
        QuoteNosVisible: Boolean;
        BlanketOrderNosVisible: Boolean;
        OrderNosVisible: Boolean;
        ReturnOrderNosVisible: Boolean;
        InvoiceNosVisible: Boolean;
        CreditMemoNosVisible: Boolean;

    procedure SetFieldsVisibility(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    begin
        QuoteNosVisible := (DocType = DocType::Quote);
        BlanketOrderNosVisible := (DocType = DocType::"Blanket Order");
        OrderNosVisible := (DocType = DocType::Order);
        ReturnOrderNosVisible := (DocType = DocType::"Return Order");
        InvoiceNosVisible := (DocType = DocType::Invoice);
        CreditMemoNosVisible := (DocType = DocType::"Credit Memo");
    end;
}

#endif