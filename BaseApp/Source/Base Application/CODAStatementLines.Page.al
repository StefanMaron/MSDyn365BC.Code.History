page 2000041 "CODA Statement Lines"
{
    Caption = 'CODA Statement Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "CODA Statement Line";
    SourceTableView = WHERE(ID = CONST(Movement));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Application Status"; "Application Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the application status of the movement line.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when you want the movement to be posted.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type to which the bank account statement line is linked.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number, that the bank account statement line is linked to.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type that the bank account statement line is linked to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account, bank, customer, vendor or fixed asset, that the bank account statement line is linked to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the movement.';
                }
                field(Information; Information)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information from the CODA file, that this movement line is linked to.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the movement, expressed in the currency code, that has been entered on the movement line.';
                }
                field("Statement Amount"; "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of this movement.';
                }
                field("Message Type"; "Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of message that is used in the Statement Message field.';
                }
                field("Type Standard Format Message"; "Type Standard Format Message")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of standard format message that will be used, when the Message Type field shows the option Standard format.';
                }
                field("Transaction Date"; "Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction date from the CODA file.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction linked to this movement line.';
                }
                field("Transaction Family"; "Transaction Family")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction family linked to this movement line.';
                }
                field(Transaction; Transaction)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction linked to this movement line.';
                }
                field("Transaction Category"; "Transaction Category")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the category of the transaction linked to the movement line.';
                }
                field("Bank Reference No."; "Bank Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reference number of the bank.';
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                field(AccName; AccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the account that has been entered on the coded bank account statement line.';
                }
                field(UnappliedAmount; UnappliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unapplied Amount';
                    Editable = false;
                    Enabled = UnappliedAmountEnable;
                    ToolTip = 'Specifies the total amount of the unapplied CODA statement lines.';
                }
                field("Balance + ""Statement Amount"""; Balance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    Enabled = BalanceEnable;
                    ToolTip = 'Specifies the balance that has accumulated in the Coded Bank Account Statement table on the line.';
                }
                field("TotalBalance + ""Statement Amount"""; TotalBalance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Balance';
                    Editable = false;
                    Enabled = TotalBalanceEnable;
                    ToolTip = 'Specifies the total balance of the CODA statement lines.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcBalance("Statement Line No.");
        GetAccount;
    end;

    trigger OnAfterGetRecord()
    begin
        InformationOnFormat(Format(Information));
    end;

    trigger OnInit()
    begin
        UnappliedAmountEnable := true;
        BalanceEnable := true;
        TotalBalanceEnable := true;
    end;

    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankStmtMgmt: Codeunit "CODA Write Statements";
        UnappliedAmount: Decimal;
        TotalBalance: Decimal;
        Balance: Decimal;
        AccName: Text[100];
        [InDataSet]
        TotalBalanceEnable: Boolean;
        [InDataSet]
        BalanceEnable: Boolean;
        [InDataSet]
        UnappliedAmountEnable: Boolean;

    local procedure CalcBalance(CodBankStmtLineNo: Integer)
    var
        CodBankStmt: Record "CODA Statement";
        TempCodBankStmtLine: Record "CODA Statement Line";
    begin
        if CodBankStmt.Get("Bank Account No.", "Statement No.") then;

        TempCodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type);
        TempCodBankStmtLine.CopyFilters(Rec);
        TempCodBankStmtLine.SetRange(Type, Type::Global);

        TotalBalance := CodBankStmt."Balance Last Statement" - "Statement Amount";
        if TempCodBankStmtLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + TempCodBankStmtLine."Statement Amount";
            UnappliedAmount := TempCodBankStmtLine."Statement Amount";
            TotalBalanceEnable := true;
        end else
            TotalBalanceEnable := false;

        Balance := CodBankStmt."Balance Last Statement" - "Statement Amount";
        TempCodBankStmtLine.SetRange("Statement Line No.", 0, CodBankStmtLineNo);
        if TempCodBankStmtLine.CalcSums("Statement Amount") then begin
            Balance := Balance + TempCodBankStmtLine."Statement Amount";
            BalanceEnable := true;
        end else
            BalanceEnable := false;

        TempCodBankStmtLine.Reset();
        TempCodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Application Status");
        TempCodBankStmtLine.SetRange("Bank Account No.", "Bank Account No.");
        TempCodBankStmtLine.SetRange("Statement No.", "Statement No.");
        TempCodBankStmtLine.SetRange("Application Status", "Application Status"::Applied);
        if TempCodBankStmtLine.CalcSums(Amount) then begin
            UnappliedAmount := UnappliedAmount - TempCodBankStmtLine.Amount;
            UnappliedAmountEnable := true;
        end else
            UnappliedAmountEnable := false;
    end;

    [Scope('OnPrem')]
    procedure GetAccount()
    begin
        AccName := '';
        if "Account No." <> '' then
            case "Account Type" of
                "Account Type"::"G/L Account":
                    if GLAcc.Get("Account No.") then
                        AccName := GLAcc.Name;
                "Account Type"::Customer:
                    if Cust.Get("Account No.") then
                        AccName := Cust.Name;
                "Account Type"::Vendor:
                    if Vend.Get("Account No.") then
                        AccName := Vend.Name;
            end;
    end;

    [Scope('OnPrem')]
    procedure Apply()
    begin
        BankStmtMgmt.Apply(Rec);
    end;

    local procedure InformationOnFormat(Text: Text[1024])
    begin
        if Information > 0 then
            Text := '***'
    end;
}

