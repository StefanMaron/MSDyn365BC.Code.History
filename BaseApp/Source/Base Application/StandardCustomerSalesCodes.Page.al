page 173 "Standard Customer Sales Codes"
{
    Caption = 'Recurring Sales Lines';
    DataCaptionFields = "Customer No.";
    PageType = List;
    SourceTable = "Standard Customer Sales Code";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number of the customer to which the standard sales code is assigned.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a standard sales code from the Standard Sales Code table.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the standard sales code.';
                }
                field("Valid From Date"; "Valid From Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day when the Create Recurring Sales Inv. batch job can be used to create sales invoices.';
                }
                field("Valid To date"; "Valid To date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day when the Create Recurring Sales Inv. batch job can be used to create sales invoices.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the direct-debit mandate that this standard customer sales code uses to create sales invoices for direct debit collection.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Insert Rec. Lines On Quotes"; "Insert Rec. Lines On Quotes")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard sales codes on sales quotes.';
                }
                field("Insert Rec. Lines On Orders"; "Insert Rec. Lines On Orders")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard sales codes on sales orders.';
                }
                field("Insert Rec. Lines On Invoices"; "Insert Rec. Lines On Invoices")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard sales codes on sales invoices.';
                }
                field("Insert Rec. Lines On Cr. Memos"; "Insert Rec. Lines On Cr. Memos")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard sales codes on sales credit memos.';
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
        area(processing)
        {
            group("&Sales")
            {
                Caption = '&Sales';
                Image = Sales;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Standard Sales Code Card";
                    RunPageLink = Code = FIELD(Code);
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
            }
        }
    }

    procedure GetSelected(var StdCustSalesCode: Record "Standard Customer Sales Code")
    begin
        CurrPage.SetSelectionFilter(StdCustSalesCode);
    end;
}

