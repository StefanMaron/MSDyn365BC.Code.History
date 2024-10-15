#if not CLEAN18
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
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of vat control report lines';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of GL Journal reconciliation by type will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
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
        Heading: Code[10];

    procedure SetGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
    begin
        GenJnlLine.Copy(NewGenJnlLine);
        Heading := GenJnlLine."Journal Batch Name";
        DeleteAll();

        if GenJnlLine.Find('-') then
            repeat
                // NAVCZ
                SaveNetChange(
                  GenJnlLine."Account Type", GenJnlLine."Account No.",
                  GenJnlLine."Amount (LCY)", GenJnlLine."VAT Amount (LCY)");
                SaveNetChange(
                  GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.",
                  -GenJnlLine."Amount (LCY)", GenJnlLine."Bal. VAT Amount (LCY)");
                GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine."Line No.");
                if GenJnlAlloc.FindSet() then
                    repeat
                        SaveNetChange(
                          GenJnlLine."Account Type"::"G/L Account", GenJnlAlloc."Account No.",
                          GenJnlAlloc.Amount, GenJnlAlloc."VAT Amount");
                    until GenJnlAlloc.Next() = 0;
            // NAVCZ
            until GenJnlLine.Next() = 0;

        OnAfterSetGenJnlLine(Rec, GenJnlLine);
        if Find('-') then;
    end;

    local procedure SaveNetChange(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; NetChange: Decimal; VATAmount: Decimal)
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        Value: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveNetChange(Rec, GenJnlLine, AccType.AsInteger(), AccNo, NetChange, IsHandled);
        if IsHandled then
            exit;

        if AccNo = '' then
            exit;
        // NAVCZ
        Value := NetChange - VATAmount;

        if Get(AccNo, AccType) then begin
            "Net Change in Jnl." := "Net Change in Jnl." + Value;
            "Balance after Posting" := "Balance after Posting" + Value;
            OnSaveNetChangeOnBeforeModify(Rec, GenJnlLine, AccType, AccNo, NetChange);
            Modify;
        end else begin
            Init;
            Type := AccType;
            "No." := AccNo;
            "Net Change in Jnl." := Value;
            case AccType of
                GenJnlLine."Account Type"::"G/L Account":
                    begin
                        GLAcc.Get(AccNo);
                        Name := GLAcc.Name;
                        GLAcc.CalcFields("Balance at Date");
                        "Balance after Posting" := GLAcc."Balance at Date" + Value;
                    end;
                GenJnlLine."Account Type"::Customer:
                    begin
                        Cust.Get(AccNo);
                        Name := Cust.Name;
                        Cust.CalcFields("Balance (LCY)");
                        "Balance after Posting" := Cust."Balance (LCY)" + Value;
                    end;
                GenJnlLine."Account Type"::Vendor:
                    begin
                        Vend.Get(AccNo);
                        Name := Vend.Name;
                        Vend.CalcFields("Balance (LCY)");
                        "Balance after Posting" := -Vend."Balance (LCY)" + Value;
                    end;
                GenJnlLine."Account Type"::"Bank Account":
                    begin
                        BankAcc.Get(AccNo);
                        Name := BankAcc.Name;
                        BankAcc.CalcFields("Balance (LCY)");
                        "Balance after Posting" := BankAcc."Balance (LCY)" + Value;
                    end;
                GenJnlLine."Account Type"::"Fixed Asset":
                    begin
                        FA.Get(AccNo);
                        Name := FA.Description;
                    end;
                GenJnlLine."Account Type"::"IC Partner":
                    begin
                        ICPartner.Get(AccNo);
                        Name := ICPartner.Name;
                    end;
                GenJnlLine."Account Type"::Employee:
                    begin
                        Employee.Get(AccNo);
                        Name := CopyStr(Employee.FullName, 1, MaxStrLen(Name));
                        Employee.CalcFields(Balance);
                        "Balance after Posting" := -Employee.Balance + Value;
                    end;
            end;
            OnSaveNetChangeOnBeforeModify(Rec, GenJnlLine, AccType, AccNo, NetChange);
            Insert;
        end;
        // NAVCZ
    end;

    procedure InsertGLAccNetChange()
    begin
        GLAcc.CalcFields("Balance at Date");
        Init;
        "No." := GLAcc."No.";
        Name := GLAcc.Name;
        "Balance after Posting" := GLAcc."Balance at Date";
        OnBeforeGLAccountNetChange(Rec, GLAcc);
        Insert;

        OnAfterInsertGLAccNetChange(Rec);
    end;

    procedure ReturnGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change")
    var
        OldGLAccountNetChange: Record "G/L Account Net Change";
    begin
        OldGLAccountNetChange := Rec;
        FindSet();
        repeat
            GLAccountNetChange.Init();
            GLAccountNetChange := Rec;
            GLAccountNetChange.Insert();
        until Next() = 0;

        Rec := OldGLAccountNetChange;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLine(var GLAccountNetChange: Record "G/L Account Net Change"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGLAccNetChange(var GLAccountNetChange: Record "G/L Account Net Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Integer; AccNo: Code[20]; var NetChange: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveNetChangeOnBeforeModify(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; NetChange: Decimal)
    begin
    end;
}
#endif
