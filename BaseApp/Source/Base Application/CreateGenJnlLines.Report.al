report 2000022 "Create Gen. Jnl. Lines"
{
    Caption = 'Create Gen. Jnl. Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Domiciliation Journal Line"; "Domiciliation Journal Line")
        {

            trigger OnAfterGetRecord()
            begin
                CreateGenJnlLineFromDomJnlLine("Domiciliation Journal Line");
                TotalAmountLCY += "Domiciliation Journal Line"."Amount (LCY)";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(GenJnlTemplate; GeneralJournalTemplateName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Template';
                    TableRelation = "Gen. Journal Template";
                    ToolTip = 'Specifies the general journal template that the entries are placed in.';

                    trigger OnValidate()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                    begin
                        if GeneralJournalTemplateName = '' then
                            GeneralJournalBatchName := '';
                    end;
                }
                field(GenJnlBatch; GeneralJournalBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Batch';
                    ToolTip = 'Specifies the general journal batch that the entries are placed in.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GeneralJournalBatches: Page "General Journal Batches";
                    begin
                        GenJournalBatch.SetRange("Journal Template Name", GeneralJournalTemplateName);
                        GeneralJournalBatches.SetTableView(GenJournalBatch);
                        if GeneralJournalBatches.RunModal = ACTION::OK then begin
                            GeneralJournalBatches.GetRecord(GenJournalBatch);
                            GeneralJournalBatchName := GenJournalBatch.Name;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                    begin
                        GenJournalBatch.Get(GeneralJournalTemplateName, GeneralJournalBatchName);
                        GenJournalBatch.TestField(Recurring, false);
                        GenJournalBatch.TestField("No. Series");
                    end;
                }
                field(PostGenJnlLines; PostGenJnlLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post General Journal Lines';
                    ToolTip = 'Specifies if you want to transfer the postings in the general journal to the general ledger.';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        BalancingDomJnlLine: Record "Domiciliation Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        BalancingDomJnlLine := "Domiciliation Journal Line";
        BalancingDomJnlLine."Customer No." := GenJnlBatch."Bal. Account No.";
        BalancingDomJnlLine.Amount := -TotalAmountLCY;
        BalancingDomJnlLine."Message 1" := '';
        BalancingDomJnlLine."Applies-to Doc. Type" := 0;
        BalancingDomJnlLine."Applies-to Doc. No." := '';
        CreateGenJnlLineFromDomJnlLine(BalancingDomJnlLine);

        if PostGenJnlLines then begin
            GenJnlLine.SetRange("Journal Template Name", GeneralJournalTemplateName);
            GenJnlLine.SetRange("Journal Batch Name", GeneralJournalBatchName);
            GenJnlLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
        end;
    end;

    trigger OnPreReport()
    var
        GLAcc: Record "G/L Account";
    begin
        // Check General Journal
        with GenJnlBatch do begin
            Reset;
            if not Get(GeneralJournalTemplateName, GeneralJournalBatchName) then
                Error(PostingNotSpecifiedErr, FieldCaption(Name));

            if not ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
                Error(BalAccTypeErr, Name);

            if "Bal. Account No." = '' then
                Error(BalAccNoErr, Name);

            if not GLAcc.Get("Bal. Account No.") then
                Error(NotGLAccErr, "Bal. Account No.");

            if not (GLAcc."Account Type" = GLAcc."Account Type"::Posting) then
                Error(NotPostingErr, GLAcc."No.");
        end;
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GeneralJournalTemplateName: Code[10];
        GeneralJournalBatchName: Code[10];
        PostGenJnlLines: Boolean;
        PostingNotSpecifiedErr: Label 'The %1 for posting is not specified.';
        BalAccTypeErr: Label 'The balance account type in %1 must be G/L Account.';
        BalAccNoErr: Label 'The balance account number in %1 is not a valid G/L Account No.';
        NotGLAccErr: Label '%1 in Journal Template is not a G/L Account No.';
        NotPostingErr: Label 'The account type in general ledger account %1 must be Posting.';
        TotalAmountLCY: Decimal;

    [Scope('OnPrem')]
    procedure FindLastGenJnlLine(var LastGenJnlLine: Record "Gen. Journal Line")
    begin
        LastGenJnlLine.SetRange("Journal Template Name", GeneralJournalTemplateName);
        LastGenJnlLine.SetRange("Journal Batch Name", GeneralJournalBatchName);
        if LastGenJnlLine.FindLast then;
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLineFromDomJnlLine(DomJnlLine: Record "Domiciliation Journal Line")
    var
        FileDomiciliations: Report "File Domiciliations";
        GenJnlLine: Record "Gen. Journal Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[10];
    begin
        DocumentNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", DomJnlLine."Posting Date", false);
        FindLastGenJnlLine(GenJnlLine);
        FileDomiciliations.SetGlobalPostingVariables(GenJnlBatch, GenJnlLine, DocumentNo);
        FileDomiciliations.SetGenJnlLine(DomJnlLine);
    end;
}

