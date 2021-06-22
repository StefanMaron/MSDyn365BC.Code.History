codeunit 99000841 "Item Ledger Entry-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        FilterReservEntry.SetSourceFilter(DATABASE::"Item Ledger Entry", 0, '', ItemLedgEntry."Entry No.", false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure Caption(ItemLedgEntry: Record "Item Ledger Entry") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo(
            '%1 %2', ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
    end;
}

