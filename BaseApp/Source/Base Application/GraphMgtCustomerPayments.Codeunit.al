codeunit 5479 "Graph Mgt - Customer Payments"
{

    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetCustomerPaymentsTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; CustomerPaymentBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", CustomerPaymentBatchName);
        GenJournalLine.SetRange("Journal Batch Name", CustomerPaymentBatchName);
    end;

    procedure SetCustomerPaymentsFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName);
    end;

    procedure SetCustomerPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DummyDate: Date;
    begin
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
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

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GenJnlLineRecordRef: RecordRef;
    begin
        GenJnlLineRecordRef.Open(DATABASE::"Gen. Journal Line");
        GraphMgtGeneralTools.UpdateIntegrationRecords(GenJnlLineRecordRef, GenJnlLine.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds;
    end;

    procedure UpdateIds()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            SetRange("Account Type", "Account Type"::Customer);

            if FindSet then
                repeat
                    UpdateCustomerID;
                    UpdateGraphContactId;
                    UpdateAppliesToInvoiceID;
                    UpdateJournalBatchID;
                    Modify(false);
                until Next = 0;
        end;
    end;
}

