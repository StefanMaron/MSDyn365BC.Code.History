codeunit 18808 "TCS-Post Preview"
{
    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure FindTCSEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    var
        TCSEntries: Record "TCS Entry";
        Navigate: page Navigate;
    begin
        if TCSEntries.ReadPermission() then begin
            TCSEntries.Reset();
            TCSEntries.SetCurrentKey("Document No.", "Posting Date");
            TCSEntries.SetFilter("Document No.", DocNoFilter);
            TCSEntries.SetFilter("Posting Date", PostingDateFilter);
            Navigate.InsertIntoDocEntry(DocumentEntry, DATABASE::"TCS Entry", 0, Copystr(TCSEntries.TableCaption(), 1, 1024), TCSEntries.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::Navigate, 'OnAfterNavigateShowRecords', '', false, false)]
    local procedure ShowEntries(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; var TempDocumentEntry: Record "Document Entry")
    var
        TCSEntries: Record "TCS Entry";
    begin
        TCSEntries.Reset();
        TCSEntries.SetFilter("Document No.", DocNoFilter);
        TCSEntries.SetFilter("Posting Date", PostingDateFilter);
        if TableID = Database::"TCS Entry" then
            PAGE.Run(page::"TCS Entries", TCSEntries);
    end;
}