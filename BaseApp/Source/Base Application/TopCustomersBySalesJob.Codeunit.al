codeunit 1328 "Top Customers By Sales Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateCustomerTopList;
    end;

    var
        AllOtherCustomersTxt: Label 'All Other Customers';

    [EventSubscriber(ObjectType::Table, 472, 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        LastCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if Sender."Object Type to Run" <> Sender."Object Type to Run"::Codeunit then
            exit;

        if Sender."Object ID to Run" <> CODEUNIT::"Top Customers By Sales Job" then
            exit;

        if not LastCustLedgerEntry.FindLast then
            exit;

        if TopCustomersBySalesBuffer.FindFirst then
            if TopCustomersBySalesBuffer.LastCustLedgerEntryNo = LastCustLedgerEntry."Entry No." then
                exit;

        Result := true;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomerTopList()
    var
        LastCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TempTopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer" temporary;
        Customer: Record Customer;
        ChartManagement: Codeunit "Chart Management";
        CustomerCounter: Integer;
        OtherCustomersSalesLCY: Decimal;
        DTUpdated: DateTime;
        LastCustomerLedgerEntryNo: Integer;
    begin
        if ChartManagement.TopCustomerListUpdatedRecently(LastCustomerLedgerEntryNo) then
            exit;

        if not LastCustLedgerEntry.FindLast then
            exit;

        if LastCustLedgerEntry."Entry No." = LastCustomerLedgerEntryNo then
            exit;

        Customer.SetCurrentKey("Sales (LCY)");
        Customer.Ascending(false);
        DTUpdated := CurrentDateTime;
        if Customer.FindSet then
            repeat
                CustomerCounter += 1;
                InsertRow(TempTopCustomersBySalesBuffer,
                  CustomerCounter, Customer."No.", Customer.Name, Customer."Sales (LCY)", LastCustLedgerEntry."Entry No.", DTUpdated);
                OtherCustomersSalesLCY -= Customer."Sales (LCY)";
            until (Customer.Next = 0) or (CustomerCounter = 10);

        if Customer.Count > 10 then begin
            CustLedgerEntry.CalcSums("Sales (LCY)");
            OtherCustomersSalesLCY += CustLedgerEntry."Sales (LCY)";
            CustomerCounter += 1;
            InsertRow(TempTopCustomersBySalesBuffer,
              CustomerCounter, '', AllOtherCustomersTxt, OtherCustomersSalesLCY, LastCustLedgerEntry."Entry No.", DTUpdated);
        end;

        if TempTopCustomersBySalesBuffer.FindSet then begin
            TopCustomersBySalesBuffer.LockTable();
            TopCustomersBySalesBuffer.DeleteAll();
            repeat
                TopCustomersBySalesBuffer.TransferFields(TempTopCustomersBySalesBuffer);
                TopCustomersBySalesBuffer.Insert();
            until TempTopCustomersBySalesBuffer.Next = 0
        end;
    end;

    local procedure InsertRow(var TempTopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer" temporary; Ranking: Integer; CustomerNo: Code[20]; CustomerName: Text[100]; SalesLCY: Decimal; LastCustLedgEntryNo: Integer; DTUpdated: DateTime)
    begin
        TempTopCustomersBySalesBuffer.Ranking := Ranking;
        TempTopCustomersBySalesBuffer.CustomerNo := CustomerNo;
        TempTopCustomersBySalesBuffer.CustomerName := CustomerName;
        TempTopCustomersBySalesBuffer.SalesLCY := SalesLCY;
        TempTopCustomersBySalesBuffer.LastCustLedgerEntryNo := LastCustLedgEntryNo;
        TempTopCustomersBySalesBuffer.DateTimeUpdated := DTUpdated;
        TempTopCustomersBySalesBuffer.Insert();
    end;
}

