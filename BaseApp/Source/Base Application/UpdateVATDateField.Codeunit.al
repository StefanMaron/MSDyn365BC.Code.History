codeunit 104051 "Update VAT Date Field"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateVATEntries();
        UpdateGLEntries();
        UpdatePurchSalesEntries();
        UpdateIssuedDocsEntries();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesBlankUpgrade()) then begin
            UpdateBlankVATEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesBlankUpgrade()) then begin
            UpdateBlankGLEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchBlankUpgrade()) then begin
            UpdatePurchSalesBlankEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsBlankUpgrade()) then begin
            UpdateIssuedDocsBlankEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsBlankUpgrade());
        end;

        
    end;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BlankDate: Date;

    local procedure UpdateVATEntries()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade()) then
            exit;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade());
    end;

    local procedure UpdateGLEntries()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade()) then
            exit;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade());
    end;

    local procedure UpdatePurchSalesEntries()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchUpgrade()) then
            exit;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchUpgrade());
    end;

    local procedure UpdateIssuedDocsEntries()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsUpgrade()) then
            exit;

        IssuedReminderHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not IssuedReminderHeader.IsEmpty then
            exit;

        IssuedFinChargeMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not IssuedFinChargeMemoHeader.IsEmpty then
            exit;

        VATDateDataTransfer.SetTables(Database::"Issued Reminder Header", Database::"Issued Reminder Header");
        VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Posting Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Issued Fin. Charge Memo Header", Database::"Issued Fin. Charge Memo Header");
        VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Posting Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsUpgrade());
    end;

    local procedure UpdateBlankVATEntries()
    begin
    end;

    local procedure UpdateBlankGLEntries()
    begin
    end;

    local procedure UpdatePurchSalesBlankEntries()
    begin
    end;

    local procedure UpdateIssuedDocsBlankEntries()
    var
        GLSetup: Record "General Ledger Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Issued Reminder Header", Database::"Issued Reminder Header");
        VATDateDataTransfer.AddSourceFilter(IssuedReminderHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Posting Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Document Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Issued Fin. Charge Memo Header", Database::"Issued Fin. Charge Memo Header");
        VATDateDataTransfer.AddSourceFilter(IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Posting Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Document Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;


}