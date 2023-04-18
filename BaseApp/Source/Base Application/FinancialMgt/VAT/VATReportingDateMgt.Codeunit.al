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
        GLSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VATDateFeatureTok: Label 'VAT Date', Locked = true;
        VATReturnStatusWarningMsg: Label 'VAT Return for the chosen period is already %1. Are you sure you want to make this change?', Comment = '%1 - The status of the VAT return.';
        VATReturnFromWarningMsg: Label 'VAT Entry is in a %1 VAT Return period. Are you sure you want to make this change?', Comment = '%1 - The status of the VAT return.';
        VATReturnPeriodClosedErr: Label 'VAT Return Period is closed for the selected date. Please select another date.';
        VATReturnFromClosedErr: Label 'VAT Entry is in a closed VAT Return Period and can not be changed.';
        VATDateNotAllowedErr: Label 'The VAT Date is not within your range of allowed posting dates.';

    procedure UpdateLinkedEntries(VATEntry: Record "VAT Entry")
    begin
        FeatureTelemetry.LogUsage('0000I9D', VATDateFeatureTok, 'VAT Date field populated');

        UpdateVATEntries(VATEntry);
        UpdateGLEntries(VATEntry);
        UpdatePostedDocuments(VATEntry);
    end;

    procedure IsVATDateModifiable() IsModifiable: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeIsVATDateModifiable(IsModifiable, IsHandled);
        if IsHandled then
            exit;

        if GLSetup.Get() then
            IsModifiable := GLSetup."VAT Reporting Date Usage" = GLSetup."VAT Reporting Date Usage"::Enabled;
    end;

    internal procedure IsVATDateUsageSetToPostingDate() IsPostingDate: Boolean
    begin
        if GLSetup.Get() then
            IsPostingDate := GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date";
    end;

    internal procedure IsVATDateUsageSetToDocumentDate() IsDocumentDate: Boolean
    begin
        if GLSetup.Get() then
            IsDocumentDate := GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date";
    end;

    procedure IsVATDateEnabled() IsEnabled: Boolean
    var
        IsHandled: Boolean;
    begin
#if not CLEAN23
        OnBeforeIsVATDateEnabled(IsEnabled, IsHandled);
#endif
        if not IsHandled then
            OnBeforeIsVATDateEnabledForUse(IsEnabled, IsHandled);
        if IsHandled then
            exit;

        if GLSetup.Get() then
            IsEnabled := GLSetup."VAT Reporting Date Usage" <> GLSetup."VAT Reporting Date Usage"::Disabled;
    end;

    procedure IsValidVATDate(VATEntry: Record "VAT Entry"): Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        SetupRecordID: RecordID;
    begin
        // check whether VAT Date is within allowed VAT Periods
        if not IsValidDate(VATEntry."VAT Reporting Date") then
            exit(false);

        // check whether VAT Date is within Allowed period fedined in Gen. Ledger Setup
        if not UserSetupManagement.IsPostingDateValidWithSetup(VATEntry."VAT Reporting Date", SetupRecordID) then
            VATEntry.FieldError(VATEntry."VAT Reporting Date", VATDateNotAllowedErr);

        exit(true);
    end;

    procedure IsValidDate(VATDate: Date): Boolean
    begin
        exit(IsValidDate(VATDate, false));
    end;

    internal procedure IsValidDate(VATDate: Date; ExistingEntry: Boolean): Boolean
    var
        VATReturnPeriod: Record "VAT Return Period";
        ConfirmManagement: Codeunit "Confirm Management";
        WarningMsg, ErrorMsg: Text;
    begin
        if ExistingEntry then begin
            WarningMsg := VATReturnFromWarningMsg;
            ErrorMsg := VATReturnFromClosedErr;
        end else begin
            WarningMsg := VATReturnStatusWarningMsg;
            ErrorMsg := VATReturnPeriodClosedErr;
        end;
        if not GLSetup.Get() then
            exit(false);
        if VATReturnPeriod.FindVATPeriodByDate(VATDate) then
            case GLSetup."Control VAT Period" of
                "VAT Period Control"::Disabled: exit(true);
                "VAT Period Control"::"Block posting within closed and warn for released period":
                    begin
                        if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                            Error(ErrorMsg);

                        VATReturnPeriod.CalcFields("VAT Return Status");
                        if VATReturnPeriod."VAT Return Status" in [VATReturnPeriod."VAT Return Status"::Released, VATReturnPeriod."VAT Return Status"::Submitted] then
                            exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(WarningMsg, Format(VATReturnPeriod."VAT Return Status")), true));
                    end;
                "VAT Period Control"::"Block posting within closed period":
                    if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                        Error(ErrorMsg);
                "VAT Period Control"::"Warn when posting in closed period":
                    if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(WarningMsg, Format(VATReturnPeriod.Status::Closed)), true));
            end;
        exit(true);
    end;

    local procedure UpdateGLEntries(VATEntry: Record "VAT Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.LoadFields("Entry No.", "Document No.", "Posting Date", "Transaction No.", "VAT Reporting Date");
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", VATEntry."Document No.");
        GLEntry.SetRange("Posting Date", VATEntry."Posting Date");
        GLEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLEntry.ModifyAll("VAT Reporting Date", VATEntry."VAT Reporting Date");
    end;

    local procedure UpdateVATEntries(VATEntry: Record "VAT Entry")
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.LoadFields("Entry No.", Type, "Document No.", "Document Type", "Posting Date", "Transaction No.", "VAT Reporting Date");
        VATEntry2.SetFilter("Entry No.", '<>%1', VATEntry."Entry No.");
        VATEntry2.SetRange(Type, VATEntry.Type);
        VATEntry2.SetRange("Document No.", VATEntry."Document No.");
        VATEntry2.SetRange("Document Type", VATEntry."Document Type");
        VATEntry2.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry2.SetRange("Transaction No.", VATEntry."Transaction No.");
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateModifiable(var IsModifiable: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateEnabledForUse(var IsEnabled: Boolean; var IsHandled: Boolean);
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by OnBeforeIsVATDateEnabledForUse with correct parameter name', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateEnabled(var IsModifiable: Boolean; var IsHandled: Boolean);
    begin
    end;
#endif
    

}