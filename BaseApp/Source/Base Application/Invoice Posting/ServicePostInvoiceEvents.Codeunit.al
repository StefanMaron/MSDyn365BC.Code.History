codeunit 827 "Service Post Invoice Events"
{
    // OnAfter events

    procedure RunOnAfterUpdateInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterUpdateInvoicePostingBuffer(InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    // OnBefore events

    procedure RunOnBeforePrepareLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var IsHandled: Boolean)
    begin
        OnBeforePrepareLine(ServiceHeader, ServiceLine, ServiceLineACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalcInvoiceDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcInvoiceDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalcLineDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcLineDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    // Prepare Line

    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; SuppressCommit: Boolean)
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine, ServiceLineACY, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; SuppressCommit: Boolean)
    begin
    end;

    // Post Balancing Entry

    procedure RunOnPostBalancingEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnAfterGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    // Post Ledger Entry

    procedure RunOnPostLedgerEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnAfterGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    // Post Lines

    procedure RunOnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
        OnPostLinesOnAfterGenJnlLinePost(GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    procedure RunOnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        OnPostLinesOnBeforeGenJnlLinePost(GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnUpdateInvoicePostingBufferOnBeforeUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnUpdateInvoicePostingBufferOnBeforeUpdate(InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInvoicePostingBufferOnBeforeUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;
}