codeunit 101 "Cust. Entry-SetAppl.ID"
{
    Permissions = TableData "Cust. Ledger Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        CustEntryApplID: Code[50];

    procedure SetApplId(var CustLedgEntry: Record "Cust. Ledger Entry"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        CustLedgEntryToUpdate: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.LockTable();
        if CustLedgEntry.FindSet then begin
            // Make Applies-to ID
            if CustLedgEntry."Applies-to ID" <> '' then
                CustEntryApplID := ''
            else begin
                CustEntryApplID := AppliesToID;
                if CustEntryApplID = '' then begin
                    CustEntryApplID := UserId;
                    if CustEntryApplID = '' then
                        CustEntryApplID := '***';
                end;
            end;
            repeat
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.Insert();
            until CustLedgEntry.Next = 0;
        end;

        if TempCustLedgEntry.FindSet then
            repeat
                CustLedgEntryToUpdate.Copy(TempCustLedgEntry);
                CustLedgEntryToUpdate.TestField(Open, true);
                CustLedgEntryToUpdate."Applies-to ID" := CustEntryApplID;
                if CustLedgEntryToUpdate."Applies-to ID" = '' then begin
                    CustLedgEntryToUpdate."Accepted Pmt. Disc. Tolerance" := false;
                    CustLedgEntryToUpdate."Accepted Payment Tolerance" := 0;
                end;
                if ((CustLedgEntryToUpdate."Amount to Apply" <> 0) and (CustEntryApplID = '')) or
                   (CustEntryApplID = '')
                then
                    CustLedgEntryToUpdate."Amount to Apply" := 0
                else
                    if CustLedgEntryToUpdate."Amount to Apply" = 0 then begin
                        CustLedgEntryToUpdate.CalcFields("Remaining Amount");
                        CustLedgEntryToUpdate."Amount to Apply" := CustLedgEntryToUpdate."Remaining Amount"
                    end;

                if CustLedgEntryToUpdate."Entry No." = ApplyingCustLedgEntry."Entry No." then
                    CustLedgEntryToUpdate."Applying Entry" := ApplyingCustLedgEntry."Applying Entry";
                CustLedgEntryToUpdate.Modify();
            until TempCustLedgEntry.Next = 0;
    end;
}

