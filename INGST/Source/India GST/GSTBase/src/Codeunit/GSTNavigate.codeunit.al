codeunit 18002 "GST Navigate"
{
    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    Local Procedure FindDetailedGSTEntries(
        var DocumentEntry: Record "Document Entry";
        DocNoFilter: Text; PostingDateFilter: Text)
    var
        DetailedGSTLedgerEntries: Record "Detailed GST Ledger Entry";
        GSTLedgerEntries: Record "GST Ledger Entry";
        Navigate: Page Navigate;
    Begin
        If GSTLedgerEntries.ReadPermission() Then Begin
            GSTLedgerEntries.Reset();
            GSTLedgerEntries.SetCurrentKey("Document No.", "Posting Date");
            GSTLedgerEntries.SetFilter("Document No.", DocNoFilter);
            GSTLedgerEntries.SetFilter("Posting Date", PostingDateFilter);
            Navigate.InsertIntoDocEntry(
                DocumentEntry,
                DATABASE::"GST Ledger Entry",
                0,
                Copystr(GSTLedgerEntries.TableCaption(), 1, 1024),
                GSTLedgerEntries.Count());
        End;

        If DetailedGSTLedgerEntries.ReadPermission() Then Begin
            DetailedGSTLedgerEntries.Reset();
            DetailedGSTLedgerEntries.SetCurrentKey("Document No.", "Posting Date");
            DetailedGSTLedgerEntries.SetFilter("Document No.", DocNoFilter);
            DetailedGSTLedgerEntries.SetFilter("Posting Date", PostingDateFilter);
            Navigate.InsertIntoDocEntry(
                DocumentEntry,
                DATABASE::"Detailed GST Ledger Entry",
                0,
                Copystr(DetailedGSTLedgerEntries.TableCaption(), 1, 1024),
                DetailedGSTLedgerEntries.Count());
        End;
    End;


}