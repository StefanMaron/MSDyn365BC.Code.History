Codeunit 18687 "TDS Preview Handler"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnGetEntries', '', false, false)]
    local procedure TDSLedgerEntry(TableNo: Integer; var RecRef: RecordRef)
    begin
        case TableNo of
            Database::"TDS Entry":
                RecRef.GetTable(TempTDSLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', false, false)]
    local procedure TDSShowEntries(TableNo: Integer)
    begin
        case TableNo of
            Database::"TDS Entry":
                Page.Run(page::"TDS Entries", TempTDSLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', false, false)]
    local procedure FillTDSEntries(var DocumentEntry: Record "Document Entry")
    var
        PreviewHandler: Codeunit "Posting Preview Event Handler";
    begin
        PreviewHandler.InsertDocumentEntry(TempTDSLedgerEntry, DocumentEntry);
    end;


    [EventSubscriber(ObjectType::Table, database::"TDS Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure SavePreviewTDSEntry(var Rec: Record "TDS Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        TempTDSLedgerEntry := Rec;
        TempTDSLedgerEntry."Document No." := '***';
        TempTDSLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc()
    begin
        DeleteTempTDSEntry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc()
    begin
        DeleteTempTDSEntry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode()
    begin
        DeleteTempTDSEntry();
    end;

    local procedure DeleteTempTDSEntry()
    begin
        TempTDSLedgerEntry.Reset();
        if not TempTDSLedgerEntry.IsEmpty() then
            TempTDSLedgerEntry.DeleteAll();
    end;

    var
        TempTDSLedgerEntry: Record "TDS Entry" temporary;
}