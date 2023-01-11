codeunit 799 "VAT Reporting Date Mgt"
{
    SingleInstance = true;
    Permissions = TableData "Sales Invoice Header" = rm,
                    TableData "Sales Cr.Memo Header" = rm,
                    TableData "Service Invoice Header" = rm,
                    TableData "Service Cr.Memo Header" = rm,
                    TableData "Issued Reminder Header" = rm,
                    TableData "Issued Fin. Charge Memo Header" = rm,
                    TableData "Purch. Inv. Header" = rm,
                    TableData "Purch. Cr. Memo Hdr." = rm,
                    TableData "G/L Entry" = rm,
                    TableData "VAT Entry" = rm,
                    TableData "VAT Return Period" = r,
                    TableData "General Ledger Setup" = r;

    trigger OnRun()
    begin    
    end;
    
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VATDateFeatureTok: Label 'VAT Date', Locked = true;
        VATReturnStatusWarningMsg: Label 'VAT Return for chosen period is already %1. Are you sure you want to make this change?', Comment = '%1 - The status of the VAT return.'; 
        VATDateNotChangedErr: Label 'VAT Return Period is closed for the selected date. Please select another date.';

    procedure UpdateLinkedEntries(VATEntry: Record "VAT Entry")
    begin
        FeatureTelemetry.LogUsage('0000I9D', VATDateFeatureTok, 'VAT Date field populated');

        UpdateVATEntries(VATEntry);
        UpdateGLEntries(VATEntry);
        UpdatePostedDocuments(VATEntry);
    end;

    procedure IsVATDateModifiable(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then
            exit(false);

        exit(GLSetup."VAT Reporting Date Usage" = GLSetup."VAT Reporting Date Usage"::Complete);
    end;

    procedure IsVATDateEnabled(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then
            exit(false);

        exit(GLSetup."VAT Reporting Date Usage" <> GLSetup."VAT Reporting Date Usage"::Disabled);
    end;

    procedure IsValidDate(VATDate: Date) : Boolean;
    var
        VATReturnPeriod: Record "VAT Return Period";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if VATReturnPeriod.FindVATPeriodByDate(VATDate) then begin
            if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                Error(VATDateNotChangedErr);

            VATReturnPeriod.CalcFields("VAT Return Status");
            if VATReturnPeriod."VAT Return Status" in [VATReturnPeriod."VAT Return Status"::Released, VATReturnPeriod."VAT Return Status"::Submitted] then
                exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(VATReturnStatusWarningMsg, Format(VATReturnPeriod."VAT Return Status")), true));

        end;
        exit(true);
    end;

    local procedure UpdateGLEntries(VATEntry: Record "VAT Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", VATEntry."Document No.");
        GLEntry.SetRange("Posting Date", VATEntry."Posting Date");
        GLEntry.ModifyAll("VAT Reporting Date", VATEntry."VAT Reporting Date");
    end;

    local procedure UpdateVATEntries(VATEntry: Record "VAT Entry")
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.SetCurrentKey("Document No.", "VAT Reporting Date", Type);
        VATEntry2.SetFilter("Entry No.", '<>%1', VATEntry."Entry No.");
        VATEntry2.SetRange("Document No.", VATEntry."Document No.");
        VATEntry2.SetRange("Document Type", VATEntry."Document Type");
        VATEntry2.SetRange(Type, VATEntry.Type);
        VATEntry2.ModifyAll("VAT Reporting Date", VATEntry."VAT Reporting Date");
    end;

    local procedure UpdatePostedDocuments(VATEntry: Record "VAT Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        RecordRef: RecordRef;
        Updated: Boolean;
    begin
        case VATEntry."Document Type" of
            VATEntry."Document Type"::Invoice:
                begin
                    if VATEntry.Type = VATEntry.Type::Sale then begin
                        FilterSalesInvoiceHeader(VATEntry, SalesInvHeader);
                        RecordRef.GetTable(SalesInvHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, SalesInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        if not Updated then begin
                            FilterServInvoiceHeader(VATEntry, ServiceInvHeader);
                            RecordRef.GetTable(ServiceInvHeader);
                            Updated := UpdateVATDateFromRecordRef(RecordRef, ServiceInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        end;
                    end;
                    if VATEntry.Type = VATEntry.Type::Purchase then begin
                        FilterPurchInvoiceHeader(VATEntry, PurchInvHeader);
                        RecordRef.GetTable(PurchInvHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, PurchInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                    end;
                end;
            VATEntry."Document Type"::"Credit Memo":
                begin
                    if VATEntry.Type = VATEntry.Type::Sale then begin
                        FilterSalesCrMemoHeader(VATEntry, SalesCrMemoHeader);
                        RecordRef.GetTable(SalesCrMemoHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        if not Updated then begin
                            FilterServCrMemoHeader(VATEntry, ServiceCrMemoHeader);
                            RecordRef.GetTable(ServiceCrMemoHeader);
                            Updated := UpdateVATDateFromRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        end;
                    end;
                    if VATEntry.Type = VATEntry.Type::Purchase then begin
                        FilterPurchCrMemoHeader(VATEntry, PurchCrMemoHeader);
                        RecordRef.GetTable(PurchCrMemoHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, PurchCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                    end;
                end;
            VATEntry."Document Type"::"Finance Charge Memo":
                begin
                    FilterIssuedFinChrgMemoHeader(VATEntry, IssuedFinChargeMemoHeader);
                    RecordRef.GetTable(IssuedFinChargeMemoHeader);
                    Updated := UpdateVATDateFromRecordRef(RecordRef, IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                end;
            VATEntry."Document Type"::Reminder:
                begin
                    FilterIssuedReminderHeader(VATEntry, IssuedReminderHeader);
                    RecordRef.GetTable(IssuedReminderHeader);
                    Updated := UpdateVATDateFromRecordRef(RecordRef, IssuedReminderHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                end;
        end;
        if Updated then
            RecordRef.Modify();
    end;

    local procedure FilterSalesInvoiceHeader(VATEntry: Record "VAT Entry"; var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("No.", VATEntry."Document No.");
        SalesInvHeader.SetRange("Posting Date", VATEntry."Posting Date");
        SalesInvHeader.SetRange("External Document No.", VATEntry."External Document No.");
    end;

    local procedure FilterSalesCrMemoHeader(VATEntry: Record "VAT Entry"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Reset();
        SalesCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        SalesCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
        SalesCrMemoHeader.SetRange("External Document No.", VATEntry."External Document No.");
    end;

    local procedure FilterServInvoiceHeader(VATEntry: Record "VAT Entry"; var ServiceInvHeader: Record "Service Invoice Header")
    begin
        ServiceInvHeader.Reset();
        ServiceInvHeader.SetRange("No.", VATEntry."Document No.");
        ServiceInvHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterServCrMemoHeader(VATEntry: Record "VAT Entry"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header");
    begin
        ServiceCrMemoHeader.Reset();
        ServiceCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        ServiceCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterIssuedReminderHeader(VATEntry: Record "VAT Entry"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.Reset();
        IssuedReminderHeader.SetRange("No.", VATEntry."Document No.");
        IssuedReminderHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterIssuedFinChrgMemoHeader(VATEntry: Record "VAT Entry"; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChargeMemoHeader.Reset();
        IssuedFinChargeMemoHeader.SetRange("No.", VATEntry."Document No.");
        IssuedFinChargeMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterPurchInvoiceHeader(VATEntry: Record "VAT Entry"; var PurchInvoiceHeader: Record "Purch. Inv. Header")
    begin
        PurchInvoiceHeader.Reset();
        PurchInvoiceHeader.SetRange("No.", VATEntry."Document No.");
        PurchInvoiceHeader.SetRange("Posting Date", VATEntry."Posting Date");
        PurchInvoiceHeader.SetRange("Vendor Invoice No.", VATEntry."External Document No.");
    end;

    local procedure FilterPurchCrMemoHeader(VATEntry: Record "VAT Entry"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHeader.Reset();
        PurchCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        PurchCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure UpdateVATDateFromRecordRef(var RecordRef: RecordRef; FieldId: Integer; VATDate: Date): Boolean
    var
        FieldRef: FieldRef;
    begin
        if RecordRef.FindFirst() then begin
            FieldRef := RecordRef.Field(FieldId);
            FieldRef.Value := VATDate;
            exit(true);
        end;
        exit(false);
    end;

}