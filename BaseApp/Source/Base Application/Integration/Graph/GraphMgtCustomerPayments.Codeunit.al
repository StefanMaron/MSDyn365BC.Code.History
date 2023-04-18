codeunit 5479 "Graph Mgt - Customer Payments"
{

    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetCustomerPaymentsTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; CustomerPaymentBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName());
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", CustomerPaymentBatchName);
        GenJournalLine.SetRange("Journal Batch Name", CustomerPaymentBatchName);
    end;

    procedure SetCustomerPaymentsFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName());
    end;

    procedure SetCustomerPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
    begin
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GraphMgtJournalLines.SetPaymentsValues(GenJournalLine, TempGenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        with GenJournalLine do begin
            SetRange("Account Type", "Account Type"::Customer);

            if FindSet() then begin
                repeat
                    UpdateCustomerID();
#if not CLEAN20                    
                    UpdateGraphContactId();
#endif
                    UpdateAppliesToInvoiceID();
                    UpdateJournalBatchID();
                    Modify(false);
                    if WithCommit then
                        APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                until Next() = 0;

                if WithCommit then
                    Commit();
            end;
        end;
    end;
}

