#pragma warning disable AS0074
#if not CLEAN21
page 36722 "Bank Rec. Dep. Lines - Dyn."
{
    Caption = 'Bank Rec. Dep. Lines';
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
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
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