codeunit 351 "Intrastat Document Completion"
{

    trigger OnRun()
    begin
    end;

    var
        IntrastatSetup: Record "Intrastat Setup";

    [EventSubscriber(ObjectType::Table, 36, 'OnBeforeInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure DefaultSalesDocuments(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get then
            exit;

        if (Rec."Document Type" = Rec."Document Type"::"Credit Memo") or
           (Rec."Document Type" = Rec."Document Type"::"Return Order")
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnBeforeInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure DefaultPurchaseDcouments(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get then
            exit;

        if (Rec."Document Type" = Rec."Document Type"::"Credit Memo") or
           (Rec."Document Type" = Rec."Document Type"::"Return Order")
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";
    end;

    [EventSubscriber(ObjectType::Table, 5900, 'OnBeforeInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure DefaultServiceDocuments(var Rec: Record "Service Header"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if (Rec."Transaction Type" <> '') or Rec.IsTemporary then
            exit;

        if not IntrastatSetup.ReadPermission then
            exit;

        if not IntrastatSetup.Get then
            exit;

        if Rec."Document Type" = Rec."Document Type"::"Credit Memo" then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Return";

        if (Rec."Document Type" = Rec."Document Type"::Invoice) or
           (Rec."Document Type" = Rec."Document Type"::Order)
        then
            Rec."Transaction Type" := IntrastatSetup."Default Trans. - Purchase";
    end;
}

