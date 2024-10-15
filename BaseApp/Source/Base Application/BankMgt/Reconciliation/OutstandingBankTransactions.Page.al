namespace Microsoft.Bank.Reconciliation;

page 1284 "Outstanding Bank Transactions"
{
    Caption = 'Outstanding Bank Transactions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Outstanding Bank Transaction";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = DocumentNoIndent;
                IndentationControls = "External Document No.";
                ShowAsTree = true;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that generated the entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that generated the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field(Applied; Rec.Applied)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been applied.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Indentation; Rec.Indentation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level of indentation for the transaction. Indented transactions usually indicate deposits.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number for this transaction.';
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
        DocumentNoIndent := Rec.Indentation;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    var
        OutstandingBankTrxTxt: Label 'Outstanding Bank Transactions';
        OutstandingPaymentTrxTxt: Label 'Outstanding Payment Transactions';
        DocumentNoIndent: Integer;

    procedure SetRecords(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary)
    begin
        Rec.Copy(TempOutstandingBankTransaction, true);
    end;

    procedure SetPageCaption(TransactionType: Option)
    begin
        if TransactionType = Rec.Type::"Bank Account Ledger Entry" then
            CurrPage.Caption(OutstandingBankTrxTxt)
        else
            CurrPage.Caption(OutstandingPaymentTrxTxt);
    end;
}

