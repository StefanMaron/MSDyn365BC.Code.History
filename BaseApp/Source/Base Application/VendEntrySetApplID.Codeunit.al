codeunit 111 "Vend. Entry-SetAppl.ID"
{
    Permissions = TableData "Vendor Ledger Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        VendEntryApplID: Code[50];
        CannotBeAppliedErr: Label '%1 cannot be applied, since it is included in a bill group.', Comment = '%1 = Description';
        CannotBeAppliedTryAgainErr: Label '%1 cannot be applied, since it is included in a bill group. Remove it from its bill group and try again.', Comment = '%1 = Description';

    procedure SetApplId(var VendLedgEntry: Record "Vendor Ledger Entry"; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        VendLedgEntryToUpdate: Record "Vendor Ledger Entry";
        CarteraSetup: Record "Cartera Setup";
        CarteraDoc: Record "Cartera Doc.";
    begin
        VendLedgEntry.LockTable();
        if VendLedgEntry.FindSet then begin
            // Make Applies-to ID
            if VendLedgEntry."Applies-to ID" <> '' then
                VendEntryApplID := ''
            else begin
                VendEntryApplID := AppliesToID;
                if VendEntryApplID = '' then begin
                    VendEntryApplID := UserId;
                    if VendEntryApplID = '' then
                        VendEntryApplID := '***';
                end;
            end;
            repeat
                TempVendLedgEntry := VendLedgEntry;
                TempVendLedgEntry.Insert();
            until VendLedgEntry.Next = 0;
        end;

        if TempVendLedgEntry.FindSet then
            repeat
                VendLedgEntryToUpdate.Copy(TempVendLedgEntry);
                VendLedgEntryToUpdate.TestField(Open, true);
                if VendLedgEntryToUpdate."Document Situation" = VendLedgEntryToUpdate."Document Situation"::"Posted BG/PO" then
                    Error(CannotBeAppliedErr, VendLedgEntryToUpdate.Description);
                if ApplyingVendLedgEntry."Document Situation" = ApplyingVendLedgEntry."Document Situation"::"Posted BG/PO" then
                    Error(CannotBeAppliedErr, ApplyingVendLedgEntry.Description);

                if CarteraSetup.ReadPermission then
                    if ((VendLedgEntryToUpdate."Document Type" = VendLedgEntryToUpdate."Document Type"::Bill) or
                        (VendLedgEntryToUpdate."Document Type" = VendLedgEntryToUpdate."Document Type"::Invoice))
                    then
                        if CarteraDoc.Get(CarteraDoc.Type::Payable, VendLedgEntryToUpdate."Entry No.") then
                            if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                                Error(CannotBeAppliedTryAgainErr, VendLedgEntryToUpdate.Description);

                VendLedgEntryToUpdate."Applies-to ID" := VendEntryApplID;
                if VendLedgEntryToUpdate."Applies-to ID" = '' then begin
                    VendLedgEntryToUpdate."Accepted Pmt. Disc. Tolerance" := false;
                    VendLedgEntryToUpdate."Accepted Payment Tolerance" := 0;
                end;

                if ((VendLedgEntryToUpdate."Amount to Apply" <> 0) and (VendEntryApplID = '')) or
                   (VendEntryApplID = '')
                then
                    VendLedgEntryToUpdate."Amount to Apply" := 0
                else
                    if VendLedgEntryToUpdate."Amount to Apply" = 0 then begin
                        VendLedgEntryToUpdate.CalcFields("Remaining Amount");
                        if VendLedgEntryToUpdate."Remaining Amount" <> 0 then
                            VendLedgEntryToUpdate."Amount to Apply" := VendLedgEntryToUpdate."Remaining Amount";
                    end;

                if VendLedgEntryToUpdate."Entry No." = ApplyingVendLedgEntry."Entry No." then
                    VendLedgEntryToUpdate."Applying Entry" := ApplyingVendLedgEntry."Applying Entry";
                VendLedgEntryToUpdate.Modify();
            until TempVendLedgEntry.Next = 0;
    end;
}

