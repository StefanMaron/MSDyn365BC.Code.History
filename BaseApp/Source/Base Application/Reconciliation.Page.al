page 345 Reconciliation
{
    Caption = 'Reconciliation';
    DataCaptionExpression = Heading;
    Editable = false;
    PageType = List;
    SourceTable = "G/L Account Net Change";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account';
                    ToolTip = 'Specifies the bank account that is being reconciled.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Net Change in Jnl."; "Net Change in Jnl.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net change that will occur on the bank when you post the journal.';
                }
                field("Balance after Posting"; "Balance after Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance after Posting';
                    ToolTip = 'Specifies the current balance on the bank account.';
                }
            }
        }
    }

    actions
    {
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Heading: Code[10];

    procedure SetGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.Copy(NewGenJnlLine);
        Heading := GenJnlLine."Journal Batch Name";
        DeleteAll();
        GLAcc.SetCurrentKey("Reconciliation Account");
        GLAcc.SetRange("Reconciliation Account", true);
        if GLAcc.Find('-') then
            repeat
                InsertGLAccNetChange;
            until GLAcc.Next = 0;

        if GenJnlLine.Find('-') then
            repeat
                SaveNetChange(
                  GenJnlLine."Account Type", GenJnlLine."Account No.",
                  Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."VAT %" / 100)));
                SaveNetChange(
                  GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.",
                  -Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."Bal. VAT %" / 100)));
            until GenJnlLine.Next = 0;
        if Find('-') then;
    end;

    local procedure SaveNetChange(AccType: Integer; AccNo: Code[20]; NetChange: Decimal)
    begin
        OnBeforeSaveNetChange(Rec, GenJnlLine, AccType, AccNo, NetChange);

        if AccNo = '' then
            exit;
        case AccType of
            GenJnlLine."Account Type"::"G/L Account":
                if not Get(AccNo) then
                    exit;
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    if AccNo <> BankAcc."No." then begin
                        BankAcc.Get(AccNo);
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("G/L Account No.");
                    end;
                    AccNo := BankAccPostingGr."G/L Account No.";
                    if not Get(AccNo) then begin
                        GLAcc.Get(AccNo);
                        InsertGLAccNetChange;
                    end;
                end;
            else
                exit;
        end;

        "Net Change in Jnl." := "Net Change in Jnl." + NetChange;
        "Balance after Posting" := "Balance after Posting" + NetChange;
        Modify;
    end;

    procedure InsertGLAccNetChange()
    begin
        GLAcc.CalcFields("Balance at Date");
        Init;
        "No." := GLAcc."No.";
        Name := GLAcc.Name;
        "Balance after Posting" := GLAcc."Balance at Date";
        OnBeforeGLAccountNetChange(Rec);
        Insert;
    end;

    procedure ReturnGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change")
    var
        OldGLAccountNetChange: Record "G/L Account Net Change";
    begin
        OldGLAccountNetChange := Rec;
        FindSet;
        repeat
            GLAccountNetChange.Init();
            GLAccountNetChange := Rec;
            GLAccountNetChange.Insert();
        until Next = 0;

        Rec := OldGLAccountNetChange;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Integer; AccNo: Code[20]; var NetChange: Decimal)
    begin
    end;
}

