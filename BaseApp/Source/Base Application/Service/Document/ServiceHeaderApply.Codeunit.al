namespace Microsoft.Service.Document;

using Microsoft.Sales.Receivables;

codeunit 5971 "Service Header Apply"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        ServHeader.Copy(Rec);
        BilToCustNo := ServHeader."Bill-to Customer No.";
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        OnRunOnAfterSetCustLedgEntryFilters(CustLedgEntry, ServHeader);
        if ServHeader."Applies-to ID" = '' then
            ServHeader."Applies-to ID" := ServHeader."No.";
        if ServHeader."Applies-to ID" = '' then
            Error(Text000, ServHeader.FieldCaption("No."), ServHeader.FieldCaption("Applies-to ID"));

        ApplyCustEntries.SetService(ServHeader, CustLedgEntry, ServHeader.FieldNo("Applies-to ID"));
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        OK := ApplyCustEntries.RunModal() = ACTION::LookupOK;
        Clear(ApplyCustEntries);
        if not OK then
            exit;
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Applies-to ID", ServHeader."Applies-to ID");
        if CustLedgEntry.FindFirst() then begin
            ServHeader."Applies-to Doc. Type" := ServHeader."Applies-to Doc. Type"::" ";
            ServHeader."Applies-to Doc. No." := '';
        end else
            ServHeader."Applies-to ID" := '';

        ServHeader.Modify();
    end;

    var
        ServHeader: Record "Service Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        BilToCustNo: Code[20];
        OK: Boolean;

        Text000: Label 'You must specify %1 or %2.';

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetCustLedgEntryFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
    end;
}

