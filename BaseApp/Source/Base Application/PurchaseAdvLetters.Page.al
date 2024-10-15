#if not CLEAN19
page 31023 "Purchase Adv. Letters"
{
    Caption = 'Purchase Adv. Letters (Obsolete)';
    CardPageID = "Purchase Advance Letter";
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Advance Letter Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220012)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the purchase advance letter.';
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor who is sending the invoice.';
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor sending the invoice.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Amount on Payment Order (LCY)"; "Amount on Payment Order (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on payment order.';
                    Visible = false;
                }
                field("Template Code"; "Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an advance template code.';
                    Visible = false;
                }
                field("Amount To Link"; "Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount not yet paid by customer.';
                    Visible = false;
                }
                field("Amount To Invoice"; "Amount To Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the paid amount for advance VAT document.';
                    Visible = false;
                }
                field("Amount To Deduct"; "Amount To Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum advance value for use in final sales invoice.';
                    Visible = false;
                }
                field("Document Linked Amount"; "Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document linked amount.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1100171003; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1100171001; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action("Purchase Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Order';
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Purchase Order";
                    RunPageLink = "Document Type" = CONST(Order),
                                  "No." = FIELD("Order No.");
                    ToolTip = 'Creates a new purchase order';
                }
            }
        }
        area(processing)
        {
            action("&Print Advance Letter")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print Advance Letter';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                ToolTip = 'Open the report for advance letter.';

                trigger OnAction()
                begin
                    PurchAdvanceLetterHeader := Rec;
                    CurrPage.SetSelectionFilter(PurchAdvanceLetterHeader);
                    PurchAdvanceLetterHeader.PrintRecords(true);
                end;
            }
        }
        area(reporting)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
}
#endif
