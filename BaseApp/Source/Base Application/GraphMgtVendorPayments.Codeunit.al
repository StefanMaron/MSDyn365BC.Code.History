codeunit 5011 "Graph Mgt - Vendor Payments"
{
    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetVendorPaymentsTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; VendorPaymentBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", VendorPaymentBatchName);
        GenJournalLine.SetRange("Journal Batch Name", VendorPaymentBatchName);
    end;

    procedure SetVendorPaymentsFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
    end;

    procedure SetVendorPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
    begin
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GraphMgtJournalLines.SetPaymentsValues(GenJournalLine, TempGenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            SetRange("Account Type", "Account Type"::Vendor);

            if FindSet() then
                repeat
                    UpdateVendorID();
                    UpdateGraphContactId();
                    UpdateAppliesToInvoiceID();
                    UpdateJournalBatchID();
                    Modify(false);
                until Next() = 0;
        end;
    end;
}