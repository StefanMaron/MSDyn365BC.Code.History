page 11747 "Cash Desk Statistics"
{
    Caption = 'Cash Desk Statistics (Obsolete)';
    Editable = false;
    PageType = Card;
    SourceTable = "Bank Account";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BalanceToDate; BalanceToDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Balance';
                    ToolTip = 'Specifies the cash desk''s start balanc denominated in the applicable foreign currency.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
            }
            group("Net Change")
            {
                Caption = 'Net Change';
                fixed(Control1220008)
                {
                    ShowCaption = false;
                    group(Released)
                    {
                        Caption = 'Released';
                        field(RelReceipt; RelReceipt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Receipts';
                            ToolTip = 'Specifies quantity of receipts';

                            trigger OnDrillDown()
                            begin
                                CashDocHeader.SetRange("Cash Desk No.", "No.");
                                CashDocHeader.SetRange(Status, CashDocHeader.Status::Released);
                                CashDocHeader.SetRange("Cash Document Type", CashDocHeader."Cash Document Type"::Receipt);
                                CopyFilter("Date Filter", CashDocHeader."Posting Date");
                                PAGE.RunModal(0, CashDocHeader);
                            end;
                        }
                        field("-RelWithdrawal"; -RelWithdrawal)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Withdrawals';
                            ToolTip = 'Specifies quantity of withdrawals';

                            trigger OnDrillDown()
                            begin
                                CashDocHeader.SetRange("Cash Desk No.", "No.");
                                CashDocHeader.SetRange(Status, CashDocHeader.Status::Released);
                                CashDocHeader.SetRange("Cash Document Type", CashDocHeader."Cash Document Type"::Withdrawal);
                                CopyFilter("Date Filter", CashDocHeader."Posting Date");
                                PAGE.RunModal(0, CashDocHeader);
                            end;
                        }
                    }
                    group(Posted)
                    {
                        Caption = 'Posted';
                        field(PostReceipt; PostReceipt)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies quantity of post receipts';

                            trigger OnDrillDown()
                            begin
                                PostedCashDocHeader.SetRange("Cash Desk No.", "No.");
                                PostedCashDocHeader.SetRange("Cash Document Type", PostedCashDocHeader."Cash Document Type"::Receipt);
                                CopyFilter("Date Filter", PostedCashDocHeader."Posting Date");
                                PAGE.RunModal(0, PostedCashDocHeader);
                            end;
                        }
                        field("-PostWithdrawal"; -PostWithdrawal)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies quantity of post withdrawals';

                            trigger OnDrillDown()
                            begin
                                PostedCashDocHeader.SetRange("Cash Desk No.", "No.");
                                PostedCashDocHeader.SetRange("Cash Document Type", PostedCashDocHeader."Cash Document Type"::Withdrawal);
                                CopyFilter("Date Filter", PostedCashDocHeader."Posting Date");
                                PAGE.RunModal(0, PostedCashDocHeader);
                            end;
                        }
                    }
                }
            }
            group(Total)
            {
                Caption = 'Total';
                field(BalanceTotal; BalanceTotal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Balance';
                    ToolTip = 'Specifies the amount of end balance cash desk.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        BankAccount: Record "Bank Account";
    begin
        BalanceToDate := 0;
        RelReceipt := 0;
        RelWithdrawal := 0;
        PostReceipt := 0;
        PostWithdrawal := 0;

        if GetFilter("Date Filter") <> '' then begin
            BankAccount."No." := "No.";
            BankAccount.SetFilter("Date Filter", '..%1', CalcDate('<-1D>', GetRangeMin("Date Filter")));
            BalanceToDate := BankAccount.CalcBalance;
        end;

        RelWithdrawal := CalcOpenedWithdrawals;
        RelReceipt := CalcOpenedReceipts;

        PostWithdrawal := CalcPostedWithdrawals;
        PostReceipt := CalcPostedReceipts;

        // total balance
        BalanceTotal := BalanceToDate + RelReceipt + RelWithdrawal + PostReceipt + PostWithdrawal;
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        PostedCashDocHeader: Record "Posted Cash Document Header";
        BalanceToDate: Decimal;
        RelReceipt: Decimal;
        RelWithdrawal: Decimal;
        PostReceipt: Decimal;
        PostWithdrawal: Decimal;
        BalanceTotal: Decimal;
}

