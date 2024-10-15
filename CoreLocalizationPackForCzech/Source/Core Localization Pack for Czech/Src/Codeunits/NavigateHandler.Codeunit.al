#pragma warning disable AL0432
codeunit 31044 "Navigate Handler CZL"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        EETEntryCZL: Record "EET Entry CZL";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text;
                                                PostingDateFilter: Text; Sender: Page Navigate)
    begin
        FindEETEntries(DocumentEntry, DocNoFilter, PostingDateFilter, Sender);
        DeleteObsoleteTables(DocumentEntry);
    end;

    local procedure FindEETEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; Sender: Page Navigate)
    begin
        if EETEntryCZL.ReadPermission() then begin
            EETEntryCZL.Reset();
            EETEntryCZL.SetCurrentKey("Document No.");
            EETEntryCZL.SetFilter("Document No.", DocNoFilter);
            Sender.InsertIntoDocEntry(DocumentEntry, DATABASE::"EET Entry CZL", 0,
                EETEntryCZL.TableCaption(), EETEntryCZL.Count());
        end;
    end;

    [Obsolete('Moved to Core Localization for Czech.', '18.0')]
    local procedure DeleteObsoleteTables(var DocumentEntry: Record "Document Entry")
    var
        DummyDocumentEntry: Record "Document Entry";
    begin
        DummyDocumentEntry.CopyFilters(DocumentEntry);
        DocumentEntry.Reset();
        DocumentEntry.SetRange("Table ID", Database::"EET Entry");
        DocumentEntry.DeleteAll();
        DocumentEntry.CopyFilters(DummyDocumentEntry);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeNavigateShowRecords', '', false, false)]
    local procedure OnBeforeNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; var TempDocumentEntry: Record "Document Entry"; var IsHandled: Boolean)
    begin
        case TableID of
            Database::"EET Entry CZL":
                begin
                    EETEntryCZL.Reset();
                    EETEntryCZL.SetFilter("Document No.", DocNoFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        Page.Run(Page::"EET Entry Card CZL", EETEntryCZL)
                    else
                        Page.Run(0, EETEntryCZL);
                    IsHandled := true;
                end;
        end;
    end;
}
