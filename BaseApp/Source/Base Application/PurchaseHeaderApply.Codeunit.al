codeunit 402 "Purchase Header Apply"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        PurchHeader.Copy(Rec);
        with PurchHeader do begin
            PayToVendorNo := "Pay-to Vendor No.";
            VendLedgEntry.SetCurrentKey("Vendor No.", Open);
            VendLedgEntry.SetRange("Vendor No.", PayToVendorNo);
            VendLedgEntry.SetRange(Open, true);
            if "Applies-to ID" = '' then
                "Applies-to ID" := "No.";
            if "Applies-to ID" = '' then
                Error(
                  Text000,
                  FieldCaption("No."), FieldCaption("Applies-to ID"));
            ApplyVendEntries.SetPurch(PurchHeader, VendLedgEntry, FieldNo("Applies-to ID"));
            ApplyVendEntries.SetRecord(VendLedgEntry);
            ApplyVendEntries.SetTableView(VendLedgEntry);
            ApplyVendEntries.LookupMode(true);
            OK := ApplyVendEntries.RunModal = ACTION::LookupOK;
            Clear(ApplyVendEntries);
            if not OK then
                exit;
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Vendor No.", Open);
            VendLedgEntry.SetRange("Vendor No.", PayToVendorNo);
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if VendLedgEntry.FindFirst then begin
                "Applies-to Doc. Type" := 0;
                "Applies-to Doc. No." := '';
            end else
                "Applies-to ID" := '';

            Modify;
        end;
    end;

    var
        Text000: Label 'You must specify %1 or %2.';
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
        PayToVendorNo: Code[20];
        OK: Boolean;
}

