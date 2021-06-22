codeunit 1001 "Job Post-Line"
{
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Job Planning Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempSalesLineJob: Record "Sales Line" temporary;
        TempPurchaseLineJob: Record "Purchase Line" temporary;
        TempJobJournalLine: Record "Job Journal Line" temporary;
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        Text000: Label 'has been changed (initial a %1: %2= %3, %4= %5)';
        Text003: Label 'You cannot change the sales line because it is linked to\';
        Text004: Label ' %1: %2= %3, %4= %5.';
        Text005: Label 'You must post more usage or credit the sale of %1 %2 in %3 %4 before you can post purchase credit memo %5 %6 = %7.';

    procedure InsertPlLineFromLedgEntry(JobLedgEntry: Record "Job Ledger Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertPlLineFromLedgEntry(JobLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if JobLedgEntry."Line Type" = JobLedgEntry."Line Type"::" " then
            exit;
        ClearAll;
        JobPlanningLine."Job No." := JobLedgEntry."Job No.";
        JobPlanningLine."Job Task No." := JobLedgEntry."Job Task No.";
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        if JobPlanningLine.FindLast then;
        JobPlanningLine."Line No." := JobPlanningLine."Line No." + 10000;
        JobPlanningLine.Init();
        JobPlanningLine.Reset();
        Clear(JobTransferLine);
        JobTransferLine.FromJobLedgEntryToPlanningLine(JobLedgEntry, JobPlanningLine);
        PostPlanningLine(JobPlanningLine);
    end;

    procedure PostPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        if JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable" then begin
            Job.Get(JobPlanningLine."Job No.");
            if not Job."Allow Schedule/Contract Lines" or
               (JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account")
            then begin
                JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
                JobPlanningLine.Insert(true);
                InsertJobUsageLink(JobPlanningLine);
                JobPlanningLine.Validate("Qty. to Transfer to Journal", 0);
                JobPlanningLine.Modify(true);
                JobPlanningLine."Job Contract Entry No." := 0;
                JobPlanningLine."Line No." := JobPlanningLine."Line No." + 10000;
                JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
            end;
        end;
        if (JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account") and
           (JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Billable)
        then
            ChangeGLNo(JobPlanningLine);
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 0);
        JobPlanningLine.Modify(true);
        if JobPlanningLine."Line Type" in
           [JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable"]
        then
            InsertJobUsageLink(JobPlanningLine);
    end;

    local procedure InsertJobUsageLink(JobPlanningLine: Record "Job Planning Line")
    var
        JobUsageLink: Record "Job Usage Link";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if not JobPlanningLine."Usage Link" then
            exit;
        JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.");
        JobUsageLink.Create(JobPlanningLine, JobLedgerEntry);
    end;

    procedure PostInvoiceContractLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        EntryType: Option Usage,Sale;
        JobLedgEntryNo: Integer;
        JobLineChecked: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforePostInvoiceContractLine(SalesHeader, SalesLine);

        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        JobPlanningLine.FindFirst;
        Job.Get(JobPlanningLine."Job No.");

        if Job."Invoice Currency Code" = '' then begin
            Job.TestField("Currency Code", SalesHeader."Currency Code");
            Job.TestField("Currency Code", JobPlanningLine."Currency Code");
            SalesHeader.TestField("Currency Code", JobPlanningLine."Currency Code");
            SalesHeader.TestField("Currency Factor", JobPlanningLine."Currency Factor");
        end else begin
            Job.TestField("Currency Code", '');
            JobPlanningLine.TestField("Currency Code", '');
        end;

        IsHandled := false;
        OnPostInvoiceContractLineOnBeforeCheckBillToCustomer(SalesHeader, SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then
            SalesHeader.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");

        OnPostInvoiceContractLineBeforeCheckJobLine(SalesHeader, SalesLine, JobPlanningLine, JobLineChecked);
        if not JobLineChecked then begin
            JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
            if JobPlanningLine.Type <> JobPlanningLine.Type::Text then
                JobPlanningLine.TestField("Qty. Transferred to Invoice");
        end;

        ValidateRelationship(SalesHeader, SalesLine, JobPlanningLine);

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                if JobPlanningLineInvoice.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.",
                     JobPlanningLineInvoice."Document Type"::Invoice, SalesHeader."No.", SalesLine."Line No.")
                then begin
                    JobPlanningLineInvoice.Delete(true);
                    JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Invoice";
                    JobPlanningLineInvoice."Document No." := SalesLine."Document No.";
                    JobLedgEntryNo := FindNextJobLedgEntryNo(JobPlanningLineInvoice);
                    JobPlanningLineInvoice.Insert(true);

                    JobPlanningLineInvoice."Invoiced Date" := SalesHeader."Posting Date";
                    JobPlanningLineInvoice."Invoiced Amount (LCY)" :=
                      CalcLineAmountLCY(JobPlanningLine, JobPlanningLineInvoice."Quantity Transferred");
                    JobPlanningLineInvoice."Invoiced Cost Amount (LCY)" :=
                      JobPlanningLineInvoice."Quantity Transferred" * JobPlanningLine."Unit Cost (LCY)";
                    JobPlanningLineInvoice."Job Ledger Entry No." := JobLedgEntryNo;
                    JobPlanningLineInvoice.Modify();
                end;
            SalesHeader."Document Type"::"Credit Memo":
                if JobPlanningLineInvoice.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.",
                     JobPlanningLineInvoice."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine."Line No.")
                then begin
                    JobPlanningLineInvoice.Delete(true);
                    JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Credit Memo";
                    JobPlanningLineInvoice."Document No." := SalesLine."Document No.";
                    JobLedgEntryNo := FindNextJobLedgEntryNo(JobPlanningLineInvoice);
                    JobPlanningLineInvoice.Insert(true);

                    JobPlanningLineInvoice."Invoiced Date" := SalesHeader."Posting Date";
                    JobPlanningLineInvoice."Invoiced Amount (LCY)" :=
                      CalcLineAmountLCY(JobPlanningLine, JobPlanningLineInvoice."Quantity Transferred");
                    JobPlanningLineInvoice."Invoiced Cost Amount (LCY)" :=
                      JobPlanningLineInvoice."Quantity Transferred" * JobPlanningLine."Unit Cost (LCY)";
                    JobPlanningLineInvoice."Job Ledger Entry No." := JobLedgEntryNo;
                    JobPlanningLineInvoice.Modify();
                end;
        end;

        OnBeforeJobPlanningLineUpdateQtyToInvoice(SalesHeader, SalesLine, JobPlanningLine, JobPlanningLineInvoice, JobLedgEntryNo);

        JobPlanningLine.UpdateQtyToInvoice;
        JobPlanningLine.Modify();

        OnAfterJobPlanningLineModify(JobPlanningLine);

        if JobPlanningLine.Type <> JobPlanningLine.Type::Text then
            PostJobOnSalesLine(JobPlanningLine, SalesHeader, SalesLine, EntryType::Sale);

        OnAfterPostInvoiceContractLine(SalesHeader, SalesLine);
    end;

    local procedure ValidateRelationship(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        Txt: Text[500];
        IsHandled: Boolean;
    begin
        OnBeforeValidateRelationship(SalesHeader, SalesLine, JobPlanningLine);

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        Txt := StrSubstNo(Text000,
            JobTask.TableCaption, JobTask.FieldCaption("Job No."), JobTask."Job No.",
            JobTask.FieldCaption("Job Task No."), JobTask."Job Task No.");

        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            if SalesLine.Type <> SalesLine.Type::" " then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::Resource then
            if SalesLine.Type <> SalesLine.Type::Resource then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            if SalesLine.Type <> SalesLine.Type::Item then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account" then
            if SalesLine.Type <> SalesLine.Type::"G/L Account" then
                SalesLine.FieldError(Type, Txt);

        if SalesLine."No." <> JobPlanningLine."No." then
            SalesLine.FieldError("No.", Txt);
        if SalesLine."Location Code" <> JobPlanningLine."Location Code" then
            SalesLine.FieldError("Location Code", Txt);
        if SalesLine."Work Type Code" <> JobPlanningLine."Work Type Code" then
            SalesLine.FieldError("Work Type Code", Txt);
        if SalesLine."Unit of Measure Code" <> JobPlanningLine."Unit of Measure Code" then
            SalesLine.FieldError("Unit of Measure Code", Txt);
        if SalesLine."Variant Code" <> JobPlanningLine."Variant Code" then
            SalesLine.FieldError("Variant Code", Txt);
        if SalesLine."Gen. Prod. Posting Group" <> JobPlanningLine."Gen. Prod. Posting Group" then
            SalesLine.FieldError("Gen. Prod. Posting Group", Txt);

        IsHandled := false;
        OnValidateRelationshipOnBeforeCheckLineDiscount(SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then
            if SalesLine."Line Discount %" <> JobPlanningLine."Line Discount %" then
                SalesLine.FieldError("Line Discount %", Txt);
        if SalesLine."Unit Cost (LCY)" <> JobPlanningLine."Unit Cost (LCY)" then
            SalesLine.FieldError("Unit Cost (LCY)", Txt);
        if SalesLine.Type = SalesLine.Type::" " then begin
            if SalesLine."Line Amount" <> 0 then
                SalesLine.FieldError("Line Amount", Txt);
        end;
        if SalesHeader."Prices Including VAT" then begin
            if JobPlanningLine."VAT %" <> SalesLine."VAT %" then
                SalesLine.FieldError("VAT %", Txt);
        end;
    end;

    procedure PostJobOnSalesLine(JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; EntryType: Option Usage,Sale)
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        JobTransferLine.FromPlanningSalesLineToJnlLine(JobPlanningLine, SalesHeader, SalesLine, JobJnlLine, EntryType);
        if SalesLine.Type = SalesLine.Type::"G/L Account" then begin
            TempSalesLineJob := SalesLine;
            TempSalesLineJob.Insert();
            InsertTempJobJournalLine(JobJnlLine, TempSalesLineJob."Line No.");
        end else
            JobJnlPostLine.RunWithCheck(JobJnlLine);
    end;

    procedure CalcLineAmountLCY(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        TotalPrice := Round(Qty * JobPlanningLine."Unit Price (LCY)", 0.01);
        exit(TotalPrice - Round(TotalPrice * JobPlanningLine."Line Discount %" / 100, 0.01));
    end;

    procedure PostGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    var
        JobJnlLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        SourceCodeSetup: Record "Source Code Setup";
        JobTransferLine: Codeunit "Job Transfer Line";
    begin
        if GenJnlLine."System-Created Entry" then
            exit;
        if GenJnlLine."Job No." = '' then
            exit;
        SourceCodeSetup.Get();
        if GenJnlLine."Source Code" = SourceCodeSetup."Job G/L WIP" then
            exit;
        GenJnlLine.TestField("Job Task No.");
        GenJnlLine.TestField("Job Quantity");
        Job.LockTable();
        JobTask.LockTable();
        Job.Get(GenJnlLine."Job No.");
        GenJnlLine.TestField("Job Currency Code", Job."Currency Code");
        JobTask.Get(GenJnlLine."Job No.", GenJnlLine."Job Task No.");
        JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTransferLine.FromGenJnlLineToJnlLine(GenJnlLine, JobJnlLine);
        OnPostGenJnlLineOnAfterTransferToJnlLine(JobJnlLine, GenJnlLine, JobJnlPostLine);

        JobJnlPostLine.SetGLEntryNo(GLEntry."Entry No.");
        JobJnlPostLine.RunWithCheck(JobJnlLine);
        JobJnlPostLine.SetGLEntryNo(0);
    end;

    procedure PostJobOnPurchaseLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10])
    var
        JobJnlLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostJobOnPurchaseLine(
            PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, JobJnlLine, IsHandled,
            TempPurchaseLineJob, TempJobJournalLine, SourceCode);
        if IsHandled then
            exit;

        if (PurchLine.Type <> PurchLine.Type::Item) and (PurchLine.Type <> PurchLine.Type::"G/L Account") then
            exit;
        Clear(JobJnlLine);
        PurchLine.TestField("Job No.");
        PurchLine.TestField("Job Task No.");
        Job.LockTable();
        JobTask.LockTable();
        Job.Get(PurchLine."Job No.");
        PurchLine.TestField("Job Currency Code", Job."Currency Code");
        JobTask.Get(PurchLine."Job No.", PurchLine."Job Task No.");
        JobTransferLine.FromPurchaseLineToJnlLine(
          PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, Sourcecode, JobJnlLine);
        JobJnlLine."Job Posting Only" := true;

        if PurchLine.Type = PurchLine.Type::"G/L Account" then begin
            TempPurchaseLineJob := PurchLine;
            TempPurchaseLineJob.Insert();
            InsertTempJobJournalLine(JobJnlLine, TempPurchaseLineJob."Line No.");
        end else
            JobJnlPostLine.RunWithCheck(JobJnlLine);
    end;

    procedure TestSalesLine(var SalesLine: Record "Sales Line")
    var
        JT: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Txt: Text[250];
    begin
        if SalesLine."Job Contract Entry No." = 0 then
            exit;
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        if JobPlanningLine.FindFirst then begin
            JT.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            Txt := Text003 + StrSubstNo(Text004,
                JT.TableCaption, JT.FieldCaption("Job No."), JT."Job No.",
                JT.FieldCaption("Job Task No."), JT."Job Task No.");
            Error(Txt);
        end;
    end;

    local procedure ChangeGLNo(var JobPlanningLine: Record "Job Planning Line")
    var
        GLAcc: Record "G/L Account";
        Job: Record Job;
        JT: Record "Job Task";
        JobPostingGr: Record "Job Posting Group";
        Cust: Record Customer;
    begin
        JT.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        Job.Get(JobPlanningLine."Job No.");
        Cust.Get(Job."Bill-to Customer No.");
        if JT."Job Posting Group" <> '' then
            JobPostingGr.Get(JT."Job Posting Group")
        else begin
            Job.TestField("Job Posting Group");
            JobPostingGr.Get(Job."Job Posting Group");
        end;
        if JobPostingGr."G/L Expense Acc. (Contract)" = '' then
            exit;
        GLAcc.Get(JobPostingGr."G/L Expense Acc. (Contract)");
        GLAcc.CheckGLAcc;
        JobPlanningLine."No." := GLAcc."No.";
        JobPlanningLine."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
    end;

    procedure CheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityPurchCredit(PurchaseHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        Job.Get(PurchaseLine."Job No.");
        if Job.GetQuantityAvailable(PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine."Variant Code", 0, 2) <
           -PurchaseLine."Return Qty. to Ship (Base)"
        then
            Error(
              Text005, Item.TableCaption, PurchaseLine."No.", Job.TableCaption,
              PurchaseLine."Job No.", PurchaseHeader."No.",
              PurchaseLine.FieldCaption("Line No."), PurchaseLine."Line No.");
    end;

    procedure PostPurchaseGLAccounts(TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; GLEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        with TempPurchaseLineJob do begin
            Reset;
            SetRange("Job No.", TempInvoicePostBuffer."Job No.");
            SetRange("No.", TempInvoicePostBuffer."G/L Account");
            SetRange("Gen. Bus. Posting Group", TempInvoicePostBuffer."Gen. Bus. Posting Group");
            SetRange("Gen. Prod. Posting Group", TempInvoicePostBuffer."Gen. Prod. Posting Group");
            SetRange("VAT Bus. Posting Group", TempInvoicePostBuffer."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", TempInvoicePostBuffer."VAT Prod. Posting Group");
            if FindSet then begin
                repeat
                    TempJobJournalLine.Reset();
                    TempJobJournalLine.SetRange("Line No.", "Line No.");
                    TempJobJournalLine.FindFirst;
                    JobJnlPostLine.SetGLEntryNo(GLEntryNo);
                    IsHandled := false;
                    OnPostPurchaseGLAccountsOnBeforeJobJnlPostLine(TempJobJournalLine, TempPurchaseLineJob, IsHandled);
                    if not IsHandled then
                        JobJnlPostLine.RunWithCheck(TempJobJournalLine);
                until Next = 0;
                DeleteAll();
            end;
        end;
    end;

    procedure PostSalesGLAccounts(TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; GLEntryNo: Integer)
    begin
        with TempSalesLineJob do begin
            Reset;
            SetRange("Job No.", TempInvoicePostBuffer."Job No.");
            SetRange("No.", TempInvoicePostBuffer."G/L Account");
            SetRange("Gen. Bus. Posting Group", TempInvoicePostBuffer."Gen. Bus. Posting Group");
            SetRange("Gen. Prod. Posting Group", TempInvoicePostBuffer."Gen. Prod. Posting Group");
            SetRange("VAT Bus. Posting Group", TempInvoicePostBuffer."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", TempInvoicePostBuffer."VAT Prod. Posting Group");
            if FindSet then begin
                repeat
                    TempJobJournalLine.Reset();
                    TempJobJournalLine.SetRange("Line No.", "Line No.");
                    TempJobJournalLine.FindFirst;
                    JobJnlPostLine.SetGLEntryNo(GLEntryNo);
                    OnPostSalesGLAccountsOnBeforeJobJnlPostLine(TempJobJournalLine, TempSalesLineJob);
                    JobJnlPostLine.RunWithCheck(TempJobJournalLine);
                until Next = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure InsertTempJobJournalLine(JobJournalLine: Record "Job Journal Line"; LineNo: Integer)
    begin
        TempJobJournalLine := JobJournalLine;
        TempJobJournalLine."Line No." := LineNo;
        TempJobJournalLine.Insert();
    end;

    procedure FindNextJobLedgEntryNo(JobPlanningLineInvoice: Record "Job Planning Line Invoice"): Integer
    var
        RelatedJobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        RelatedJobPlanningLineInvoice.SetCurrentKey("Document Type", "Document No.", "Job Ledger Entry No.");
        RelatedJobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type");
        RelatedJobPlanningLineInvoice.SetRange("Document No.", JobPlanningLineInvoice."Document No.");
        if RelatedJobPlanningLineInvoice.FindLast then
            exit(RelatedJobPlanningLineInvoice."Job Ledger Entry No." + 1);
        exit(JobLedgEntry.GetLastEntryNo() + 1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvoiceContractLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlLineFromLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineUpdateQtyToInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobLedgerEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoiceContractLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJobOnPurchaseLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean; var TempPurchaseLineJob: Record "Purchase Line"; var TempJobJournalLine: Record "Job Journal Line"; var Sourcecode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRelationship(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnAfterTransferToJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line"; var JobJnlPostLine: Codeunit "Job Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineBeforeCheckJobLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var JobLineChecked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineOnBeforeCheckBillToCustomer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchaseGLAccountsOnBeforeJobJnlPostLine(var JobJournalLine: Record "Job Journal Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesGLAccountsOnBeforeJobJnlPostLine(var JobJournalLine: Record "Job Journal Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRelationshipOnBeforeCheckLineDiscount(var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;
}

