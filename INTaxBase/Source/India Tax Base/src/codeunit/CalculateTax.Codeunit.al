codeunit 18543 "Calculate Tax"
{
    //Call General Journal Line Related Use Cases
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddGenJnlLineUseCaseEventstoLibrary()
    var
        TaxUseCaseLibrary: Codeunit "Use Case Event Library";
    begin
        TaxUseCaseLibrary.AddUseCaseEventToLibrary('CallTaxEngineOnGenJnlLine', Database::"Gen. Journal Line", 'Calculate Tax on General Journal line');
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterValidateGenJnlLineFields(Var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Tax", 'OnAfterValidateGenJnlLineFields', '', false, false)]
    local procedure HandleGenJnlLineUseCase(var GenJnlLine: Record "Gen. Journal Line")
    var
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        TaxCaseExecution.HandleEvent(
            'CallTaxEngineOnGenJnlLine',
            GenJnlLine,
            GenJnlLine."Currency Code",
            GenJnlLine."Currency Factor");
    end;

    procedure CallTaxEngineOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var xGenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."System-Created Entry" then
            exit;
        if (GenJnlLine.Amount = 0) and (xGenJnlLine.Amount = 0) then
            exit;
        OnAfterValidateGenJnlLineFields(GenJnlLine);
    end;

    //Call Sales Line Related Use Cases
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddSalesUseCaseEventstoLibrary()
    var
        TaxUseCaseLibrary: Codeunit "Use Case Event Library";
    begin
        TaxUseCaseLibrary.AddUseCaseEventToLibrary('CallTaxEngineOnSalesLine', Database::"Sales Line", 'Calculate Tax on Sales line');
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterValidateSalesLineFields(Var SalesLine: Record "Sales Line");
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Tax", 'OnAfterValidateSalesLineFields', '', false, false)]
    local procedure HandleSalesUseCase(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxCaseExecution.HandleEvent(
            'CallTaxEngineOnSalesLine',
            SalesLine,
            SalesHeader."Currency Code",
            SalesHeader."Currency Factor");
    end;

    procedure CallTaxEngineOnSalesLine(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line")
    begin
        if (SalesLine.Quantity = 0) and (xSalesLine.Quantity = 0) then
            exit;

        OnAfterValidateSalesLineFields(SalesLine);
    end;

    //Call Purchase Line Related Use Cases
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddPurchaseUseCaseEventstoLibrary()
    var
        TaxUseCaseLibrary: Codeunit "Use Case Event Library";
    begin
        TaxUseCaseLibrary.AddUseCaseEventToLibrary('CallTaxEngineOnPurchaseLine', Database::"Purchase Line", 'Calculate Tax on Purchase Line');
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterValidatePurchaseLineFields(Var PurchaseLine: Record "Purchase Line");
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Tax", 'OnAfterValidatePurchaseLineFields', '', false, false)]
    local procedure HandlePurchaseUseCase(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        TaxCaseExecution.HandleEvent(
            'CallTaxEngineOnPurchaseLine',
            PurchaseLine,
            PurchaseHeader."Currency Code",
            PurchaseHeader."Currency Factor");
    end;

    procedure CallTaxEngineOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line")
    begin
        if (PurchaseLine.Quantity = 0) and (xPurchaseLine.Quantity = 0) then
            exit;

        OnAfterValidatePurchaseLineFields(PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostVAT', '', false, false)]
    local procedure OnBeforePostVAT(VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
        if (VATPostingSetup."VAT Bus. Posting Group" = '') and (VATPostingSetup."VAT Prod. Posting Group" = '') then
            IsHandled := true;
    end;
}