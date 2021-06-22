page 638 "IC Outbox Purchase Doc."
{
    Caption = 'IC Outbox Purchase Doc.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "IC Outbox Purchase Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("IC Transaction No."; "IC Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the intercompany transaction. The transaction number indicates which line in the IC Outbox Transaction table the document is related to.';
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field("Transaction Source"; "Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the payment discount percentage that is granted if you pay on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
            }
            part(ICOutboxPurchLines; "IC Outbox Purchase Lines")
            {
                ApplicationArea = Intercompany;
                SubPageLink = "IC Transaction No." = FIELD("IC Transaction No."),
                              "IC Partner Code" = FIELD("IC Partner Code"),
                              "Transaction Source" = FIELD("Transaction Source");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Document)
            {
                Caption = '&Document';
                Image = Document;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    RunObject = Page "IC Document Dimensions";
                    RunPageLink = "Table ID" = CONST(428),
                                  "Transaction No." = FIELD("IC Transaction No."),
                                  "IC Partner Code" = FIELD("IC Partner Code"),
                                  "Transaction Source" = FIELD("Transaction Source"),
                                  "Line No." = CONST(0);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }
}

