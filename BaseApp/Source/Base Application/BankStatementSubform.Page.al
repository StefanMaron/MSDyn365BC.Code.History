page 11707 "Bank Statement Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Bank Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1220018)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies type od partner (customer, vendor, bank account).';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank statement.';
                    Visible = false;
                }
                field("Cust./Vendor Bank Account Code"; "Cust./Vendor Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code of the customer or vendor.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment''s description.';
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
                    BlankZero = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the amount for payment.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount in the local currency for payment.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Bank Statement Currency Code"; "Bank Statement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank statement currency code which is setup in the bank card.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        BankStatement: Record "Bank Statement Header";
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        BankStatement.Get("Bank Statement No.");
                        ChangeExchangeRate.SetParameter("Bank Statement Currency Code", "Bank Statement Currency Factor",
                          BankStatement."Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Bank Statement Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                    end;
                }
                field("Amount (Bank Stat. Currency)"; "Amount (Bank Stat. Currency)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in bank statement currencythat the bank statement line contains.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
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
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        BankStatementHeader: Record "Bank Statement Header";
        BankAccount: Record "Bank Account";
    begin
        if BankStatementHeader.Get("Bank Statement No.") then begin
            BankAccount.Get(BankStatementHeader."Bank Account No.");
            "Constant Symbol" := BankAccount."Default Constant Symbol";
            "Specific Symbol" := BankAccount."Default Specific Symbol";
            "Currency Code" := BankStatementHeader."Currency Code";
            "Bank Statement Currency Code" := BankStatementHeader."Bank Statement Currency Code";
            "Bank Statement Currency Factor" := BankStatementHeader."Bank Statement Currency Factor";
        end else
            if BankAccount.Get(BankAccountNo) then begin
                "Constant Symbol" := BankAccount."Default Constant Symbol";
                "Specific Symbol" := BankAccount."Default Specific Symbol";
                "Currency Code" := BankAccount."Currency Code";
            end;
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm;
    end;

    var
        BankAccountNo: Code[20];

    [Scope('OnPrem')]
    procedure SetParameters(NewBankAccountNo: Code[20])
    begin
        BankAccountNo := NewBankAccountNo;
    end;

    local procedure OnActivateForm()
    var
        BankStatementHeader: Record "Bank Statement Header";
    begin
        if "Line No." = 0 then
            if BankStatementHeader.Get("Bank Statement No.") then begin
                Validate("Bank Statement Currency Code", BankStatementHeader."Bank Statement Currency Code");
                "Bank Statement Currency Factor" := BankStatementHeader."Bank Statement Currency Factor";
                CurrPage.Update;
            end;
    end;
}

