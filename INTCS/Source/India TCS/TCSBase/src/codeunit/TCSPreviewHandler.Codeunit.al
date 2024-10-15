Codeunit 18809 "TCS Preview Handler"
{
    SingleInstance = true;

    var
        TempTCSLedgerEntry: Record "TCS Entry" temporary;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnGetEntries', '', false, false)]
    local procedure TCSLedgerEntry(TableNo: Integer; var RecRef: RecordRef)

    begin
        if TableNo = DATABASE::"TCS Entry" then
            RecRef.GETTABLE(TempTCSLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', false, false)]
    local procedure TCSShowWntries(TableNo: Integer)
    begin
        if TableNo = DATABASE::"TCS Entry" then
            PAGE.Run(page::"TCS Entries", TempTCSLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', false, false)]
    local procedure FillTCSentries(var DocumentEntry: Record "Document Entry")
    var
        PreviewHandler: Codeunit "Posting Preview Event Handler";
    begin
        PreviewHandler.InsertDocumentEntry(TempTCSLedgerEntry, DocumentEntry);
    end;


    [EventSubscriber(ObjectType::Table, database::"TCS Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure SavePreviewTCSEntry(var Rec: Record "TCS Entry"; RunTrigger: Boolean)
    var
    begin
        if Rec.IsTemporary() then
            exit;
        TempTCSLedgerEntry := Rec;
        TempTCSLedgerEntry."Document No." := '***';
        TempTCSLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc()
    begin
        TempTCSLedgerEntry.Reset();
        if not TempTCSLedgerEntry.IsEmpty() then
            TempTCSLedgerEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc()
    begin
        TempTCSLedgerEntry.Reset();
        if not TempTCSLedgerEntry.IsEmpty() then
            TempTCSLedgerEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode()
    begin
        TempTCSLedgerEntry.Reset();
        if not TempTCSLedgerEntry.IsEmpty() then
            TempTCSLedgerEntry.DeleteAll();
    end;
}