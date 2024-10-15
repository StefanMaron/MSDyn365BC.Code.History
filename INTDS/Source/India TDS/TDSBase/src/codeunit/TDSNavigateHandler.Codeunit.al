Codeunit 18686 "TDS Navigate Handler"
{

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure FindTDSEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    var
        TDSEntry: Record "TDS Entry";
    begin
        if TDSEntry.ReadPermission() then begin
            TDSEntry.SetCurrentKey("Document No.", "Posting Date");
            TDSEntry.SetFilter("Document No.", DocNoFilter);
            TDSEntry.SetFilter("Posting Date", PostingDateFilter);
            Navigate.InsertIntoDocEntry(DocumentEntry, DATABASE::"TDS Entry", 0, Copystr(TDSEntry.TableCaption(), 1, 1024), TDSEntry.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::Navigate, 'OnAfterNavigateShowRecords', '', false, false)]
    local procedure ShowEntries(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; var TempDocumentEntry: Record "Document Entry")
    var
        TDSEntry: Record "TDS Entry";
    begin
        TDSEntry.SetRange("Document No.", DocNoFilter);
        TDSEntry.SetFilter("Posting Date", PostingDateFilter);
        if TableID = Database::"TDS Entry" then
            PAGE.Run(Page::"TDS Entries", TDSEntry);
    end;

    var
        Navigate: Page Navigate;
}