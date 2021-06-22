codeunit 401 "Sales Header Apply"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        with SalesHeader do begin
            BilToCustNo := "Bill-to Customer No.";
            CustLedgEntry.SetCurrentKey("Customer No.", Open);
            CustLedgEntry.SetRange("Customer No.", BilToCustNo);
            CustLedgEntry.SetRange(Open, true);
            if "Applies-to ID" = '' then
                "Applies-to ID" := "No.";
            if "Applies-to ID" = '' then
                Error(
                  Text000,
                  FieldCaption("No."), FieldCaption("Applies-to ID"));
            ApplyCustEntries.SetSales(SalesHeader, CustLedgEntry, FieldNo("Applies-to ID"));
            ApplyCustEntries.SetRecord(CustLedgEntry);
            ApplyCustEntries.SetTableView(CustLedgEntry);
            ApplyCustEntries.LookupMode(true);
            OK := ApplyCustEntries.RunModal = ACTION::LookupOK;
            Clear(ApplyCustEntries);
            if not OK then
                exit;
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Customer No.", Open);
            CustLedgEntry.SetRange("Customer No.", BilToCustNo);
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if CustLedgEntry.FindFirst then begin
                "Applies-to Doc. Type" := 0;
                "Applies-to Doc. No." := '';
            end else
                "Applies-to ID" := '';

            Modify;
        end;
    end;

    var
        Text000: Label 'You must specify %1 or %2.';
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        BilToCustNo: Code[20];
        OK: Boolean;
}

