page 11712 "Issued Bank Statement Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Issued Bank Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1220025)
            {
                ShowCaption = false;
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the bank statement line.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of partner (customer, vendor, bank account).';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the bank statement line contains.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the local currency for payment.';
                }
                field("Amount (Bank Stat. Currency)"; "Amount (Bank Stat. Currency)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in bank statement currencythat the bank statement line contains.';
                    Visible = false;
                }
                field("Bank Statement Currency Code"; "Bank Statement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank statement currency code which is setup in the bank card.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        IssuedBankStatementHeader: Record "Issued Bank Statement Header";
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        IssuedBankStatementHeader.Get("Bank Statement No.");
                        ChangeExchangeRate.Editable(false);
                        ChangeExchangeRate.SetParameter("Bank Statement Currency Code", "Bank Statement Currency Factor",
                          IssuedBankStatementHeader."Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Bank Statement Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                    end;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of bank statement lines';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank statement.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

