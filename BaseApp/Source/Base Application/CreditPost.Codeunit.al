codeunit 31052 "Credit - Post"
{
    Permissions = TableData "Posted Credit Header" = i,
                  TableData "Posted Credit Line" = i;
    TableNo = "Credit Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    var
        Balance: Decimal;
        TempAmount: Decimal;
        i: Integer;
    begin
        OnBeforePostCreditDoc(Rec);
        OnCheckCreditPostRestrictions;

        if Status <> Status::Released then
            CODEUNIT.Run(CODEUNIT::"Release Credit Document", Rec);

        CreditsSetup.Get();
        CreditsSetup.TestField("Credit Bal. Account No.");

        SourceCodeSetup.Get();
        GeneralLedgSetup.Get();

        CalcFields("Credit Balance (LCY)");
        Balance := "Credit Balance (LCY)";

        CheckRoundingAccounts(Balance);

        i := 1;
        CreditLine.Reset();
        CreditLine.SetRange("Credit No.", "No.");
        if CreditLine.Find('-') then begin
            Window.Open(
              '#1#################################\\' +
              Text008Msg);
            Window.Update(1, StrSubstNo(Text009Msg, "No."));
            repeat
                Window.Update(2, i);
                Clear(GenJnlLine);
                GenJnlLine.Compensation := CreditLine."Source Entry No." <> 0;
                GenJnlLine.Validate("Posting Date", "Posting Date");
                GenJnlLine.Validate("Document No.", "No.");
                GenJnlLine.Validate("Account Type", CreditLine."Source Type" + 1);
                GenJnlLine.Validate("Account No.", CreditLine."Source No.");
                GenJnlLine."Posting Group" := CreditLine."Posting Group";
                GenJnlLine.Validate("Document Date", "Document Date");
                GenJnlLine.Validate("Currency Code", CreditLine."Currency Code");
                if CreditLine."Currency Code" <> '' then
                    GenJnlLine.Validate("Currency Factor", CreditLine."Currency Factor");
                GenJnlLine.Validate(Description, Description);
                GenJnlLine.Validate(Amount, -CreditLine.Amount);
                GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
                GenJnlLine.Validate("Bal. Account No.", CreditsSetup."Credit Bal. Account No.");
                GenJnlLine.Validate("Applies-to ID", "No.");
                GenJnlLine."Dimension Set ID" := CreditLine."Dimension Set ID";
                GenJnlLine."Shortcut Dimension 1 Code" := CreditLine."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CreditLine."Global Dimension 2 Code";

                CreditManagement.SetAppliesToID(CreditLine, "No.");

                TempAmount := CreditLine."Amount (LCY)";
                Clear(CreditLine."Amount (LCY)");
                CreditLine.Modify();

                GenJnlLine."Source Code" := SourceCodeSetup.Credit;
                GenJnlLine."System-Created Entry" := true;
                GenJnlPostLine.RunWithCheck(GenJnlLine);

                CreditLine."Amount (LCY)" := TempAmount;
                CreditLine.Modify();

                CreditManagement.SetAppliesToID(CreditLine, '');
                i += 1;
            until CreditLine.Next() = 0;

            if Balance <> 0 then begin
                Clear(GenJnlLine);
                GenJnlLine.Validate("Posting Date", "Posting Date");
                GenJnlLine.Validate("Document No.", "No.");
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                case true of
                    Balance < 0:
                        GenJnlLine.Validate("Account No.", CreditsSetup."Credit Rounding Account");
                    Balance > 0:
                        GenJnlLine.Validate("Account No.", CreditsSetup."Debit Rounding Account");
                end;
                GenJnlLine.Validate("Document Date", "Document Date");
                GenJnlLine.Validate(Description, Description);
                GenJnlLine.Validate(Amount, Balance);
                GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
                GenJnlLine.Validate("Bal. Account No.", CreditsSetup."Credit Bal. Account No.");

                GenJnlLine."Dimension Set ID" := CreditLine."Dimension Set ID";

                GenJnlLine."Shortcut Dimension 1 Code" := CreditLine."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CreditLine."Global Dimension 2 Code";

                GenJnlLine."Source Code" := SourceCodeSetup.Credit;
                GenJnlLine."System-Created Entry" := true;
                GenJnlPostLine.RunWithCheck(GenJnlLine);
            end;

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            // Create posted credit, delete released credit;
            Clear(PostedCreditHeader);
            PostedCreditHeader.TransferFields(Rec);
            PostedCreditHeader.Insert();
            Clear(CreditLine);
            CreditLine.SetRange("Credit No.", "No.");
            CreditLine.FindSet();
            repeat
                Clear(PostedCreditLine);
                PostedCreditLine.TransferFields(CreditLine);
                PostedCreditLine."Credit No." := PostedCreditHeader."No.";
                PostedCreditLine.Insert();
            until CreditLine.Next() = 0;

            UpdateIncomingDocument("Incoming Document Entry No.", "Posting Date", PostedCreditHeader."No.");

            CreditLine.DeleteAll();
            Delete;
            Window.Close;
        end else
            Error(Text002Err);

        OnAfterPostCreditDoc(Rec, GenJnlPostLine, PostedCreditHeader."No.");
    end;

    var
        CreditLine: Record "Credit Line";
        GenJnlLine: Record "Gen. Journal Line";
        PostedCreditHeader: Record "Posted Credit Header";
        PostedCreditLine: Record "Posted Credit Line";
        CreditsSetup: Record "Credits Setup";
        SourceCodeSetup: Record "Source Code Setup";
        GeneralLedgSetup: Record "General Ledger Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CreditManagement: Codeunit CreditManagement;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        Text002Err: Label 'There is nothing to post.';
        Text008Msg: Label 'Posting lines              #2######.', Comment = '%2 = progress bar';
        Text009Msg: Label 'Credit %1.', Comment = '%1 = number of credit';
        PreviewMode: Boolean;

    local procedure CheckRoundingAccounts(Balance: Decimal)
    begin
        CreditsSetup.Get();
        case true of
            Balance < 0:
                CreditsSetup.TestField("Credit Rounding Account");
            Balance > 0:
                CreditsSetup.TestField("Debit Rounding Account");
        end;
    end;

    local procedure UpdateIncomingDocument(IncomingDocNo: Integer; PostingDate: Date; DocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocNo, PostingDate, DocNo);
    end;

    [Scope('OnPrem')]
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCreditDoc(var CreditHdr: Record "Credit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCreditDoc(var CreditHdr: Record "Credit Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PostedCreditHdrNo: Code[20])
    begin
    end;
}

