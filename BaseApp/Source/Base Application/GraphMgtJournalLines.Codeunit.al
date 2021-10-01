codeunit 5478 "Graph Mgt - Journal Lines"
{

    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetJournalLineTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; JournalLineBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", JournalLineBatchName);
        GenJournalLine.SetRange("Journal Batch Name", JournalLineBatchName);
    end;

    procedure SetJournalLineTemplateAndBatchV2(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
    end;

    procedure SetJournalLineFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName);
    end;

    procedure SetJournalLineFiltersV1(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName);
    end;

    procedure SetJournalLineValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DummyDate: Date;
    begin
        GenJournalLine.Validate("Account Type", TempGenJournalLine."Account Type");
        GenJournalLine.Validate("Account No.", TempGenJournalLine."Account No.");
        if TempGenJournalLine."Posting Date" <> DummyDate then
            GenJournalLine.Validate("Posting Date", TempGenJournalLine."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        if TempGenJournalLine."Document No." <> '' then
            GenJournalLine.Validate("Document No.", TempGenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", TempGenJournalLine."External Document No.");
        GenJournalLine.Validate(Amount, TempGenJournalLine.Amount);
        if TempGenJournalLine.Description <> '' then
            GenJournalLine.Validate(Description, TempGenJournalLine.Description);
        GenJournalLine.Validate(Comment, TempGenJournalLine.Comment);
        GenJournalLine.Validate("Bal. Account No.", '');
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
            GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
            GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        end
    end;

    procedure SetPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DummyDate: Date;
    begin
        if not IsNullGuid(TempGenJournalLine."Account Id") then
            GenJournalLine.Validate("Account Id", TempGenJournalLine."Account Id");
        GenJournalLine.Validate("Account No.", TempGenJournalLine."Account No.");
        if TempGenJournalLine."Contact Graph Id" <> '' then
            GenJournalLine.Validate("Contact Graph Id", TempGenJournalLine."Contact Graph Id");
        if TempGenJournalLine."Posting Date" <> DummyDate then
            GenJournalLine.Validate("Posting Date", TempGenJournalLine."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Document No.", TempGenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", TempGenJournalLine."External Document No.");
        GenJournalLine.Validate(Amount, TempGenJournalLine.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine."Applies-to Doc. No." := TempGenJournalLine."Applies-to Doc. No.";
        if not IsNullGuid(TempGenJournalLine."Applies-to Invoice Id") then
            GenJournalLine.Validate("Applies-to Invoice Id", TempGenJournalLine."Applies-to Invoice Id");
        if TempGenJournalLine.Description <> '' then
            GenJournalLine.Validate(Description, TempGenJournalLine.Description);
        GenJournalLine.Validate(Comment, TempGenJournalLine.Comment);
        GenJournalLine.Validate("Bal. Account No.", '');
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
            GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
            GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        end
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GenJnlLineRecordRef: RecordRef;
    begin
        GenJnlLineRecordRef.Open(DATABASE::"Gen. Journal Line");
        GraphMgtGeneralTools.UpdateIntegrationRecords(GenJnlLineRecordRef, GenJnlLine.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds;
    end;

    procedure UpdateIds()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            SetRange("Account Type", "Account Type"::"G/L Account");

            if FindSet then
                repeat
                    UpdateAccountID;
                    UpdateJournalBatchID;
                    Modify(false);
                until Next() = 0;
        end;
    end;
}

