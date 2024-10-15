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
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
        Heading: Code[10];

    procedure SetGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
    begin
        GenJnlLine.Copy(NewGenJnlLine);
        Heading := GenJnlLine."Journal Batch Name";
        DeleteAll;

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
                if GenJnlAlloc.FindSet then
                    repeat
                        SaveNetChange(
                          GenJnlLine."Account Type"::"G/L Account", GenJnlAlloc."Account No.",
                          GenJnlAlloc.Amount, GenJnlAlloc."VAT Amount");
                    until GenJnlAlloc.Next = 0;
            // NAVCZ
            until GenJnlLine.Next = 0;
        if Find('-') then;
    end;

    [Scope('OnPrem')]
    [Obsolete('The functionality of GL Journal reconciliation by type will be removed and this function should not be used. (Removed in release 01.2021)','15.3')]
    procedure SetBankAccReconLine(var NewBankAccReconLn: Record "Bank Acc. Reconciliation Line")
    begin
        // NAVCZ
        BankAccReconLn.Copy(NewBankAccReconLn);
        DeleteAll;

        if BankAccReconLn.FindSet then
            repeat
                SaveNetChange(
                  BankAccReconLn."Account Type", BankAccReconLn."Account No.",
                  -BankAccReconLn."Statement Amount (LCY)", 0);
                SaveNetChange(
                  BankAccReconLn."Account Type"::"Bank Account", BankAccReconLn."Bank Account No.",
                  BankAccReconLn."Statement Amount (LCY)", 0);
            until BankAccReconLn.Next = 0;
        if FindSet then;
    end;

    local procedure SaveNetChange(AccType: Integer; AccNo: Code[20]; NetChange: Decimal; VATAmount: Decimal)
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        Value: Decimal;
    begin
        OnBeforeSaveNetChange(Rec, GenJnlLine, AccType, AccNo, NetChange);

        if AccNo = '' then
            exit;
        // NAVCZ
        Value := NetChange - VATAmount;

        if Get(AccNo, AccType) then begin
            "Net Change in Jnl." := "Net Change in Jnl." + Value;
            "Balance after Posting" := "Balance after Posting" + Value;
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
            Insert;
        end;
        // NAVCZ
    end;

    local procedure InsertGLAccNetChange()
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
            GLAccountNetChange.Init;
            GLAccountNetChange := Rec;
            GLAccountNetChange.Insert;
        until Next = 0;

        Rec := OldGLAccountNetChange;
    end;

    [Scope('OnPrem')]
    [Obsolete('This function is not used anywhere. (Removed in release 01.2021)','15.3')]
    procedure SwapGenJnlLine(var SrcGenJnlLine: Record "Gen. Journal Line"; var NewGenJnlLine: Record "Gen. Journal Line")
    begin
        // NAVCZ
        NewGenJnlLine."Posting Date" := SrcGenJnlLine."Posting Date";
        NewGenJnlLine."Document No." := SrcGenJnlLine."Document No.";
        NewGenJnlLine.Description := SrcGenJnlLine.Description;
        NewGenJnlLine."Currency Code" := SrcGenJnlLine."Currency Code";
        NewGenJnlLine.Amount := -SrcGenJnlLine.Amount;
        NewGenJnlLine."Debit Amount" := -SrcGenJnlLine."Debit Amount";
        NewGenJnlLine."Credit Amount" := -SrcGenJnlLine."Credit Amount";
        NewGenJnlLine."Amount (LCY)" := -SrcGenJnlLine."Amount (LCY)";
        NewGenJnlLine."Currency Factor" := SrcGenJnlLine."Currency Factor";
        NewGenJnlLine."Shortcut Dimension 1 Code" := SrcGenJnlLine."Shortcut Dimension 1 Code";
        NewGenJnlLine."Shortcut Dimension 2 Code" := SrcGenJnlLine."Shortcut Dimension 2 Code";
        NewGenJnlLine."Account Type" := SrcGenJnlLine."Bal. Account Type";
        NewGenJnlLine."Account No." := SrcGenJnlLine."Bal. Account No.";
        SrcGenJnlLine."Bal. Account Type" := SrcGenJnlLine."Bal. Account Type"::"G/L Account";
        SrcGenJnlLine."Bal. Account No." := '';
        SrcGenJnlLine."System-Created Entry" := false;
        // NAVCZ
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

