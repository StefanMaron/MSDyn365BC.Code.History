codeunit 351 "Intrastat Document Completion"
{

    trigger OnRun()
    begin
    end;

    var
        IntrastatSetup: Record "Intrastat Setup";

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure DefaultSalesDocuments(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get() then
            exit;

        if (Rec."Document Type" = Rec."Document Type"::"Credit Memo") or
           (Rec."Document Type" = Rec."Document Type"::"Return Order")
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";

        OnAfterDefaultSalesDocuments(Rec, IntrastatSetup);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure DefaultPurchaseDocuments(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get() then
            exit;

        if (Rec."Document Type" = Rec."Document Type"::"Credit Memo") or
           (Rec."Document Type" = Rec."Document Type"::"Return Order")
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";

        OnAfterDefaultPurchaseDocuments(Rec, IntrastatSetup);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure DefaultServiceDocuments(var Rec: Record "Service Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get() then
            exit;

        if Rec."Document Type" = Rec."Document Type"::"Credit Memo" then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";

        OnAfterDefaultServiceDocuments(Rec, IntrastatSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDefaultPurchaseDocuments(var PurchaseHeader: Record "Purchase Header"; IntrastatSetup: Record "Intrastat Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDefaultSalesDocuments(var SalesHeader: Record "Sales Header"; IntrastatSetup: Record "Intrastat Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDefaultServiceDocuments(var ServiceHeader: Record "Service Header"; IntrastatSetup: Record "Intrastat Setup")
    begin
    end;
}

