page 7000037 "Check Discount Credit Limit"
{
    Caption = 'Check Discount Credit Limit';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    InstructionalText = 'The credit limit for discount with this bank will be exceeded. Do you still want to proceed?';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field("Posted Receiv. Bills Rmg. Amt."; "Posted Receiv. Bills Rmg. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Discounted so far';
                    ToolTip = 'Shows the amount pending from the receivables registered at this bank.';
                }
                field(CurrBillGrAmount; CurrBillGrAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount of this Bill Group';
                }
                field(AmountSelected; AmountSelected)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount Selected';
                    Visible = AmountSelectedVisible;
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Amount';
                }
                field("Credit Limit for Discount"; "Credit Limit for Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit limit for the discount of bills available at this particular bank.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                }
                action("St&atements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                }
                action("Chec&k Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.", "Entry Status", "Check No.");
                }
                separator(Action41)
                {
                }
                action("&Operation Fees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Operation Fees';
                    RunObject = Page "Operation Fees";
                    RunPageLink = Code = FIELD("Operation Fees Code"),
                                  "Currency Code" = FIELD("Currency Code");
                }
                action("Customer Ratings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Ratings';
                    Image = CustomerRating;
                    RunObject = Page "Customer Ratings";
                    RunPageLink = Code = FIELD("Customer Ratings Code"),
                                  "Currency Code" = FIELD("Currency Code");
                }
                separator(Action5)
                {
                    Caption = '';
                }
                action("Bill &Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill &Groups';
                    Image = VoucherGroup;
                    RunObject = Page "Bill Groups List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                }
                action("Posted Bill Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Bill Groups';
                    Image = PostedVoucherGroup;
                    RunObject = Page "Posted Bill Groups List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                }
                separator(Action7)
                {
                    Caption = '';
                }
                action("Payment O&rders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment O&rders';
                    RunObject = Page "Payment Orders List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                }
                action("Posted P&ayment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted P&ayment Orders';
                    Image = PostedPayment;
                    RunObject = Page "Posted Payment Orders List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                }
                separator(Action50)
                {
                }
                action("Posted Recei&vable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Recei&vable Bills';
                    Image = PostedReceivableVoucher;
                    RunObject = Page "Bank Cat. Posted Receiv. Bills";
                }
                action("Posted Pa&yable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Pa&yable Bills';
                    Image = PostedPayableVoucher;
                    RunObject = Page "Bank Cat. Posted Payable Bills";
                }
            }
        }
    }

    trigger OnInit()
    begin
        AmountSelectedVisible := true;
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm;
    end;

    var
        CurrBillGrAmount: Decimal;
        AmountSelected: Decimal;
        TotalAmount: Decimal;
        [InDataSet]
        AmountSelectedVisible: Boolean;

    [Scope('OnPrem')]
    procedure SetValues(CurrAmount: Decimal; SelAmount: Decimal)
    begin
        CurrBillGrAmount := CurrAmount;
        AmountSelected := SelAmount;
    end;

    local procedure OnActivateForm()
    begin
        SetRange("Dealing Type Filter", "Dealing Type Filter"::Discount);
        SetRange("Status Filter", "Status Filter"::Open);
        CalcFields("Posted Receiv. Bills Amt.");
        TotalAmount := "Posted Receiv. Bills Rmg. Amt." + CurrBillGrAmount + AmountSelected;
        AmountSelectedVisible := AmountSelected <> 0;
    end;
}

