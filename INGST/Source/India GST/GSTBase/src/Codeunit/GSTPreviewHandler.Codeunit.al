Codeunit 18003 "GST Preview Handler"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnGetEntries', '', false, false)]
    local procedure GSTLedgerEntry(TableNo: Integer; var RecRef: RecordRef)
    begin
        case TableNo of
            Database::"GST Ledger Entry":
                RecRef.GetTable(TempGSTLedgerEntry);
            Database::"Detailed GST Ledger Entry":
                RecRef.GetTable(TempDetailedGSTLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', false, false)]
    local procedure GSTShowWntries(TableNo: Integer)
    begin
        case TableNo of
            Database::"GST Ledger Entry":
                Page.Run(Page::"GST Ledger Entry", TempGSTLedgerEntry);
            Database::"Detailed GST Ledger Entry":
                Page.Run(Page::"Detailed GST Ledger Entry", TempDetailedGSTLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', false, false)]
    local procedure FillGSTentries(var DocumentEntry: Record "Document Entry")
    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
    begin
        PostingPreviewEventHandler.InsertDocumentEntry(TempGSTLedgerEntry, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempDetailedGSTLedgerEntry, DocumentEntry);
    end;


    [EventSubscriber(ObjectType::Table, Database::"GST Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure SavePreviewGSTEntry(var Rec: Record "GST Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        TempGSTLedgerEntry := Rec;
        TempGSTLedgerEntry."Document No." := DocumentNoTxt;
        TempGSTLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed GST Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure SavePreviewDetailedGSTEntry(var Rec: Record "Detailed GST Ledger Entry")
    begin
        if Rec.IsTemporary() then
            exit;
        TempDetailedGSTLedgerEntry := Rec;
        TempDetailedGSTLedgerEntry."Document No." := DocumentNoTxt;
        TempDetailedGSTLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateShowRecords', '', false, false)]
    local procedure ShowEntries(
        TableID: Integer;
        DocNoFilter: Text;
        PostingDateFilter: Text;
        var TempDocumentEntry: Record "Document Entry")
    var
        GSTLedgerEntries: Record "GST Ledger Entry";
        DetailedGSTLedgerEntries: Record "Detailed GST Ledger Entry";
    begin
        case TableID of
            Database::"GST Ledger Entry":
                begin
                    GSTLedgerEntries.Reset();
                    GSTLedgerEntries.SetRange("Document No.", DocNoFilter);
                    GSTLedgerEntries.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, GSTLedgerEntries);
                end;
            Database::"Detailed GST Ledger Entry":
                begin
                    DetailedGSTLedgerEntries.Reset();
                    DetailedGSTLedgerEntries.SetRange("Document No.", DocNoFilter);
                    DetailedGSTLedgerEntries.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, DetailedGSTLedgerEntries);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc()
    begin
        TempGSTLedgerEntry.Reset();
        if not TempGSTLedgerEntry.IsEmpty() then
            TempGSTLedgerEntry.DeleteAll();

        TempDetailedGSTLedgerEntry.Reset();
        if not TempDetailedGSTLedgerEntry.IsEmpty() then
            TempDetailedGSTLedgerEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc()
    begin
        TempGSTLedgerEntry.Reset();
        if not TempGSTLedgerEntry.IsEmpty() then
            TempGSTLedgerEntry.DeleteAll();

        TempDetailedGSTLedgerEntry.Reset();
        if not TempDetailedGSTLedgerEntry.IsEmpty() then
            TempDetailedGSTLedgerEntry.DeleteAll();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode()
    begin
        TempGSTLedgerEntry.Reset();
        if not TempGSTLedgerEntry.IsEmpty() then
            TempGSTLedgerEntry.DeleteAll();

        TempDetailedGSTLedgerEntry.Reset();
        if not TempDetailedGSTLedgerEntry.IsEmpty() then
            TempDetailedGSTLedgerEntry.DeleteAll();
    end;

    var
        TempGSTLedgerEntry: Record "GST Ledger Entry" temporary;
        TempDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry" temporary;
        DocumentNoTxt: Label '***', Locked = true;
}
