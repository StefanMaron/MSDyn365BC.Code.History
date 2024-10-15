#pragma warning disable AS0074
#if not CLEAN21
page 10122 "Bank Rec. Dep. Lines Subform"
{
    Caption = 'Bank Rec. Dep. Lines Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Rec. Line";
    SourceTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.")
                      WHERE("Record Type" = CONST(Deposit));
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#pragma warning restore AS0074

    layout
    {
        area(content)
        {
            field("BankRecHdr.""Bank Account No."""; BankRecHdr."Bank Account No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account No.';
                Editable = false;
                Visible = false;
                ToolTip = 'Specifies the bank account that the bank statement line applies to.';
            }
            field("BankRecHdr.""Statement No."""; BankRecHdr."Statement No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement No.';
                Editable = false;
                Visible = false;
                ToolTip = 'Specifies the bank reconciliation statement number that this line applies to.';
            }
            field("BankRecHdr.""Statement Date"""; BankRecHdr."Statement Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Date';
                Editable = false;
                Visible = false;
                ToolTip = 'Specifies the bank reconciliation statement date that this line applies to.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Collapse Status"; Rec."Collapse Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the collapse status for the reconciliation line.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Statement Date for Check or Deposit type. For Adjustment type lines, the entry will be the actual date the posting.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the entry on the journal line is.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    Editable = false;
                    ToolTip = 'Specifies the type of account that the journal line entry will be posted to.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the account number that the journal line entry will be posted to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the transaction on the bank reconciliation line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                }
                field(Cleared; Cleared)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the check on the line has been cleared, as indicated on the bank statement.';

                    trigger OnValidate()
                    begin
                        ClearedOnAfterValidate();
                    end;
                }
                field("Cleared Amount"; Rec."Cleared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount cleared by the bank, as indicated by the bank statement.';

                    trigger OnValidate()
                    begin
                        ClearedAmountOnAfterValidate();
                    end;
                }
                field("""Cleared Amount"" - Amount"; Rec."Cleared Amount" - Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    Editable = false;
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies that you can select the number of the G/L, customer, vendor or bank account to which a balancing entry for the line will posted.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the amounts on the line, as it will be posted to the G/L.';
                    Visible = false;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    Editable = false;
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
            }
            field(BankStatementCleared; BankRecHdr."Cleared Inc./Dpsts. Per Stmnt.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement that this line applies to.';
            }
            field(TotalCleared; BankRecHdr."Total Cleared Deposits")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Cleared';
                Editable = false;
                ToolTip = 'Specifies the total amount of the lines that are marked as cleared.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Deposit/Transfers Dimensions")
                {
                    ApplicationArea = Suite;
                    Caption = '&Deposit/Transfers Dimensions';
                    ToolTip = 'View this deposit''s default dimensions.';

                    trigger OnAction()
                    begin
                        LookupLineDimensions();
                    end;
                }
                action("E&xpand Deposit Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xpand Deposit Line';
                    Image = ExpandDepositLine;
                    ToolTip = 'Expand the collapsed deposit line. ';

                    trigger OnAction()
                    begin
                        ExpandCurrLine();
                    end;
                }
                action("Collapse Deposit Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Collapse Deposit Lines';
                    ShortCutKey = 'Shift+Ctrl+X';
                    ToolTip = 'Collapse expanded deposit lines.';

                    trigger OnAction()
                    begin
                        CollapseCurrLine();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Action1908000204)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xpand Deposit Line';
                    Image = ExpandDepositLine;
                    ToolTip = 'Expand the collapsed deposit line. ';

                    trigger OnAction()
                    begin
                        ExpandCurrLine();
                    end;
                }
                action(Action1908000304)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Collapse Deposit Lines';
                    ToolTip = 'Collapse expanded deposit lines.';

                    trigger OnAction()
                    begin
                        CollapseCurrLine();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OnActivateForm();
    end;

    var
        BankRecHdr: Record "Bank Rec. Header";

    procedure SetupTotals()
    begin
        if BankRecHdr.Get("Bank Account No.", "Statement No.") then
            BankRecHdr.CalcFields("Total Cleared Deposits");
    end;

    procedure LookupLineDimensions()
    begin
        ShowDimensions();
        CurrPage.SaveRecord();
    end;

    procedure GetTableID(): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        AllObj.FindFirst();
        exit(AllObj."Object ID");
    end;

    procedure ExpandCurrLine()
    begin
        ExpandLine(Rec);
        CurrPage.Update(false);
    end;

    procedure CollapseCurrLine()
    begin
        CollapseLines(Rec);
        CurrPage.Update(false);
    end;

    local procedure ClearedOnAfterValidate()
    begin
        CurrPage.Update();
        SetupTotals();
    end;

    local procedure ClearedAmountOnAfterValidate()
    begin
        CurrPage.Update();
        SetupTotals();
    end;

    local procedure OnActivateForm()
    begin
        SetupTotals();
    end;
}

#endif