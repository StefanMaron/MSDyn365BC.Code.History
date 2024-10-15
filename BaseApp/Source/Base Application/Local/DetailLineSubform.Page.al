page 11000003 "Detail Line Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "Detail Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the detail line.';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                    Visible = false;
                }
                field("Serial No. (Entry)"; Rec."Serial No. (Entry)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the ledger entry that this detail line is linked to.';
                }
                field("Currency Code (Entry)"; Rec."Currency Code (Entry)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the employee ledger entry, vendor ledger entry, or customer ledger entry that is linked.';
                    Visible = false;
                }
                field("Amount (Entry)"; Rec."Amount (Entry)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount (including VAT) you want to pay or collect.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the amount (including VAT) you want to pay or collect.';
                    Visible = true;
                }
                field(PercentageAmount; PercentageAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '%';
                    DecimalPlaces = 0 : 2;
                    ToolTip = 'Specifies the percentage of the amount given in Total that you want pay or collect.';

                    trigger OnValidate()
                    begin
                        if PercentageAmount <= 0 then
                            Error(Text1000001);
                        Validate("Amount (Entry)", CalculateBalance("Currency Code (Entry)") * PercentageAmount / 100);
                    end;
                }
                field("CalculateBalance(""Currency Code"")"; CalculateBalance("Currency Code"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total of the remaining amounts of all linked employee ledger, vendor ledger, or customer ledger entries.';
                }
                field("CalculateBalance(""Currency Code (Entry)"")"; CalculateBalance("Currency Code (Entry)"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code (Entry)";
                    AutoFormatType = 1;
                    Caption = 'Total (Posting)';
                    Editable = false;
                    ToolTip = 'Specifies the total of the remaining amounts of all linked employee ledger, vendor ledger or customer ledger entries.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the detail line.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections for.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections for.';
                    Visible = false;
                }
                field(Bank; Bank)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the bank you want to perform payments to, or collections from. This is the bank of your customer, employee, or vendor.';
                    Visible = false;
                }
                field("Our Bank"; Rec."Our Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of your bank, through which you want to perform payments or collections.';
                    Visible = false;
                }
                field("Transaction Mode"; Rec."Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                    Visible = false;
                }
                field("Order"; Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order type of the payment history line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PercentageAmount := Round(CalculatePartOfBalance() * 100, 0.01, '<');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Propline: Record "Proposal Line";
    begin
        if CurrPage.Editable then begin

            Propline.Get("Our Bank", "Connect Lines");
            Date := Propline."Transaction Date";
            "Account Type" := Propline."Account Type";
            "Account No." := Propline."Account No.";
            Date := Propline."Transaction Date";
            "Transaction Mode" := Propline."Transaction Mode";
            Bank := Propline.Bank;

            InitRecord();
        end;
    end;

    var
        Text1000001: Label 'Values should be greater than zero';
        PercentageAmount: Decimal;
}

