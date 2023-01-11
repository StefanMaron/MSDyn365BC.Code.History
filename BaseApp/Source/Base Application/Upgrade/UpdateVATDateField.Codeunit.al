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
    end;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BlankDate: Date;
        
    local procedure UpdateVATEntries()
    var
        VATEntry: Record "VAT Entry";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade()) then
            exit;

        VATEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not VATEntry.IsEmpty then
            exit;
        
        VATDateDataTransfer.SetTables(Database::"VAT Entry", Database::"VAT Entry");
        VATDateDataTransfer.AddFieldValue(VATEntry.FieldNo("Posting Date"), VATEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade());
    end;

    local procedure UpdateGLEntries()
    var
        GLEntry: Record "G/L Entry";
        TotalRows: Integer;
        FromNo, ToNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade()) then
            exit;
        
        GLEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not GLEntry.IsEmpty() then
            exit;
        
        GLEntry.Reset();
        TotalRows := GLEntry.Count();
        ToNo := 0;

        while ToNo < TotalRows do begin
            // Batch size 5 million
            FromNo := ToNo + 1;
            ToNo := FromNo + 5000000;
            
            if ToNo > TotalRows then
                ToNo := TotalRows;
            
            DataTransferGLEntries(FromNo, ToNo);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade());
    end;

    local procedure DataTransferGLEntries(FromEntryNo: Integer; ToEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATDateDataTransfer: DataTransfer;
    begin
        VATDateDataTransfer.SetTables(Database::"G/L Entry", Database::"G/L Entry");
        VATDateDataTransfer.AddSourceFilter(GLEntry.FieldNo("Entry No."), '%1..%2', FromEntryNo, ToEntryNo);
        VATDateDataTransfer.AddFieldValue(GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;

    local procedure UpdatePurchSalesEntries()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchUpgrade()) then
            exit;

        SalesInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not SalesInvHeader.IsEmpty then
            exit;
        
        SalesCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not SalesCrMemoHeader.IsEmpty then
            exit;
        
        ServiceInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not ServiceInvHeader.IsEmpty then
            exit;
        
        ServiceCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not ServiceCrMemoHeader.IsEmpty then
            exit;
        
        PurchInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not PurchInvHeader.IsEmpty then
            exit;
        
        PurchCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not PurchCrMemoHeader.IsEmpty then
            exit;
        
        VATDateDataTransfer.SetTables(Database::"Sales Invoice Header", Database::"Sales Invoice Header");
        VATDateDataTransfer.AddFieldValue(SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Header");
        VATDateDataTransfer.AddFieldValue(SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Service Invoice Header", Database::"Service Invoice Header");
        VATDateDataTransfer.AddFieldValue(ServiceInvHeader.FieldNo("Posting Date"), ServiceInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
        
        VATDateDataTransfer.SetTables(Database::"Service Cr.Memo Header", Database::"Service Cr.Memo Header");
        VATDateDataTransfer.AddFieldValue(ServiceCrMemoHeader.FieldNo("Posting Date"), ServiceCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Purch. Inv. Header", Database::"Purch. Inv. Header");
        VATDateDataTransfer.AddFieldValue(PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Cr. Memo Hdr.");
        VATDateDataTransfer.AddFieldValue(PurchCrMemoHeader.FieldNo("Posting Date"), PurchCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

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


}