page 35611 "Posted Purch. Advance Reports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Purchase Advance Statements';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Inv. Header";
    SourceTableView = WHERE("Empl. Purchase" = CONST(true));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Order Address Code"; "Order Address Code")
                {
                    Visible = false;
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';

                    trigger OnDrillDown()
                    begin
                        SetRange("No.");
                        PAGE.RunModal(PAGE::"Posted Purchase Invoice", Rec)
                    end;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount including VAT.';

                    trigger OnDrillDown()
                    begin
                        SetRange("No.");
                        PAGE.RunModal(PAGE::"Posted Purchase Invoice", Rec)
                    end;
                }
                field("Buy-from Post Code"; "Buy-from Post Code")
                {
                    ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                {
                    ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Contact"; "Buy-from Contact")
                {
                    ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
                    Visible = false;
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Post Code"; "Pay-to Post Code")
                {
                    ToolTip = 'Specifies the post code of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                {
                    Visible = false;
                }
                field("Pay-to Contact"; "Pay-to Contact")
                {
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ToolTip = 'Specifies the entry''s posting date.';
                    Visible = false;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Agreement No."; "Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with this header.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                    Visible = true;
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ToolTip = 'Specifies when the related invoice must be paid.';
                    Visible = false;
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
                    Visible = false;
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = false;
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
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
            group("A&dvance")
            {
                Caption = 'A&dvance';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Posted Advance Statement";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'Shift+F7';
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Purchase Invoice Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Invoice"),
                                  "No." = FIELD("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    PurchInvHeader.Copy(Rec);
                    CurrPage.SetSelectionFilter(PurchInvHeader);
                    PurchInvHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    var
        PurchInvHeader: Record "Purch. Inv. Header";
}

