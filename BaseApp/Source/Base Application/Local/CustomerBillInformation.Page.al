page 35480 "Customer Bill Information"
{
    Caption = 'Customer Bill Information';
    PageType = CardPart;
    SourceTable = "Customer Bill Header";

    layout
    {
        area(content)
        {
            field(TotalPayments; TotalPayments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Payments';
                Editable = false;
                ToolTip = 'Specifies the total payments.';
            }
            field(Balance; Balance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Balance';
                Editable = false;
                ToolTip = 'Specifies the bank balance.';
            }
            field(NewBalance; NewBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Bank Balance';
                Editable = false;
                ToolTip = 'Specifies if this is a new bank balance.';
            }
            field(CreditLimit; CreditLimit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Credit Limit';
                Editable = false;
                ToolTip = 'Specifies the bank credit limit.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance();
    end;

    trigger OnOpenPage()
    begin
        CalcBalance();
    end;

    var
        Balance: Decimal;
        TotalPayments: Decimal;
        NewBalance: Decimal;
        CreditLimit: Decimal;

    [Scope('OnPrem')]
    procedure CalcBalance()
    var
        BankAcc: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        BillPostingGroup: Record "Bill Posting Group";
        GLAcc: Record "G/L Account";
    begin
        if "Bank Account No." <> '' then begin
            BankAcc.Get("Bank Account No.");
            if Type <> Type::" " then begin
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
                BillPostingGroup.Get("Bank Account No.", "Payment Method Code");
                case Type of
                    Type::"Bills For Collection":
                        begin
                            if BillPostingGroup."Bills For Collection Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills For Collection Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                    Type::"Bills For Discount":
                        begin
                            if BillPostingGroup."Bills For Discount Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills For Discount Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                    Type::"Bills Subject To Collection":
                        begin
                            if BillPostingGroup."Bills Subj. to Coll. Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills Subj. to Coll. Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                end;
            end;
            CalcFields("Total Amount");
            TotalPayments := "Total Amount";
            NewBalance := Balance + TotalPayments;
            CreditLimit := -BankAcc."Credit Limit";
        end else begin
            TotalPayments := 0;
            Balance := 0;
            NewBalance := 0;
            CreditLimit := 0;
        end;
    end;
}

