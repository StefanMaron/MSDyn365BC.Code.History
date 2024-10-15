report 1497 "Trans. Bank Rec. to Gen. Jnl."
{
    Caption = 'Trans. Bank Rec. to Gen. Jnl.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bank Acc. Reconciliation"; "Bank Acc. Reconciliation")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.") WHERE("Statement Type" = CONST("Bank Reconciliation"));
            dataitem("Bank Acc. Reconciliation Line"; "Bank Acc. Reconciliation Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Statement Line No.");

                trigger OnAfterGetRecord()
                var
                    SourceCodeSetup: Record "Source Code Setup";
                begin
                    if (Difference = 0) or (Type > Type::"Bank Account Ledger Entry") then
                        CurrReport.Skip;

                    GenJnlLine.Init;
                    GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
                    GenJnlLine.Validate("Posting Date", "Transaction Date");
                    SourceCodeSetup.Get;
                    GenJnlLine."Source Code" := SourceCodeSetup."Trans. Bank Rec. to Gen. Jnl.";
                    if "Document No." <> '' then
                        GenJnlLine."Document No." := "Document No."
                    else
                        if GenJnlBatch."No. Series" <> '' then
                            GenJnlLine."Document No." := NoSeriesMgt.GetNextNo(
                                GenJnlBatch."No. Series", "Transaction Date", false);
                    GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";

                    if (GenJnlBatch."Bal. Account No." <> '') and
                       ((GenJnlBatch."Bal. Account Type" <> GenJnlBatch."Bal. Account Type"::"Bank Account") or
                        (GenJnlBatch."Bal. Account No." <> "Bank Acc. Reconciliation"."Bank Account No."))
                    then begin
                        GenJnlLine.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type");
                        GenJnlLine.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                        GenJnlLine.Validate(Amount, Difference);
                    end else begin
                        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Account Type"::"Bank Account");
                        GenJnlLine.Validate("Bal. Account No.", "Bank Acc. Reconciliation"."Bank Account No.");
                        GenJnlLine.Validate(Amount, -Difference);
                    end;

                    GenJnlLine.Description := Description;
                    UpdateGenJnlLine(GenJnlLine, "Bank Acc. Reconciliation Line");
                    OnBeforeGenJnlLineInsert(GenJnlLine, "Bank Acc. Reconciliation Line");
                    GenJnlLine.Insert;
                end;

                trigger OnPreDataItem()
                begin
                    GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                    GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                    if GenJnlBatch.Name <> '' then
                        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name)
                    else
                        GenJnlLine.SetRange("Journal Batch Name", '');

                    GenJnlLine.LockTable;
                    if GenJnlLine.FindLast then;
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange("Statement Type", BankAccRecon."Statement Type");
                SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
                SetRange("Statement No.", BankAccRecon."Statement No.");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Template';
                        NotBlank = true;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the general journal template that the entries are placed in.';
                    }
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Batch';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the general journal batch that the entries are placed in.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(2);
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(0);
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                Text := GenJnlBatch.Name;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                        end;
                    }
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
    begin
        GenJnlManagement.TemplateSelectionFromBatch(GenJnlBatch);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlManagement: Codeunit GenJnlManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;

    procedure SetBankAccRecon(var UseBankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        BankAccRecon := UseBankAccRecon;
    end;

    procedure InitializeRequest(GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10])
    begin
        GenJnlLine."Journal Template Name" := GenJnlTemplateName;
        GenJnlLine."Journal Batch Name" := GenJnlBatchName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}

