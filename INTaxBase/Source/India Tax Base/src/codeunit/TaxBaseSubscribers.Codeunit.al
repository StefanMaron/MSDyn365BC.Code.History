codeunit 18544 "Tax Base Subscribers"
{
    local procedure CallTaxEngineForPurchaseLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                OnBeforeCallingTaxEngineFromPurchLine(PurchaseHeader, PurchaseLine);
                CalculateTax.CallTaxEngineOnPurchaseLine(PurchaseLine, PurchaseLine);
            until PurchaseLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Applies-to Doc. No.', false, false)]
    local procedure OnAfterValidateEventAppliesToDocNo(var Rec: Record "Purchase Header")
    begin
        CallTaxEngineForPurchaseLines(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterAppliesToDocNoOnLookup', '', false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var PurchaseHeader: Record "Purchase Header")
    begin
        CallTaxEngineForPurchaseLines(PurchaseHeader);
    end;

    local procedure UpdateTaxAmount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then begin
            SalesHeader.Modify();
            repeat
                CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);
            until SalesLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, database::"Sales Header", 'OnAfterValidateEvent', 'Applies-to Doc. No.', false, false)]
    local procedure OnAfterValidateAppliesToDoc(var Rec: Record "Sales Header")
    begin
        UpdateTaxAmount(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Sales Header", 'OnAfterAppliesToDocNoOnLookup', '', false, false)]
    local procedure OnAfterAppliesToDocNoOnLookupSales(var SalesHeader: Record "Sales Header")
    begin
        UpdateTaxAmount(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Applies-to Doc. No.', false, false)]
    local procedure OnAfterValidateAppliesToDocGeneral(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Gen. Jnl.-Apply", 'OnAfterRun', '', false, false)]
    local procedure OnAfterValidateAppliesToID(var GenJnlLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        OnBeforeCallingTaxEngineFromGenJnlLine(GenJnlLine);
        CalculateTax.CallTaxEngineOnGenJnlLine(GenJnlLine, GenJnlLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo', '', false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(GenJournalLine, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo', '', false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(GenJournalLine, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Role Center Notification Mgt.", 'OnIsRunningPreview', '', false, false)]
    local procedure OnIsPreviewNotification(var isPreview: Boolean)
    begin
        isPreview := true;
    end;

    [EventSubscriber(ObjectType::Page, page::"Thirty Day Trial Dialog", 'OnIsRunningPreview', '', false, false)]
    local procedure OnIsPreviewTrialDialog(var isPreview: Boolean)
    begin
        isPreview := true;
    end;

    [EventSubscriber(ObjectType::Page, page::"Extend Trial Wizard", 'OnIsRunningPreview', '', false, false)]
    local procedure OnIsPreviewExtendTrialDialog(var isPreview: Boolean)
    begin
        isPreview := true;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCallingTaxEngineFromPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCallingTaxEngineFromGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetTCSAmount(Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetTCSAmountFromTransNo(TransactionNo: Integer; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetTDSAmount(Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetTDSAmountFromTransNo(TransactionNo: Integer; var Amount: Decimal)
    begin
    end;
}