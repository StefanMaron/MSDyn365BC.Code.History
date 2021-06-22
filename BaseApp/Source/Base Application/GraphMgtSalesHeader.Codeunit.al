codeunit 5474 "Graph Mgt - Sales Header"
{
    // // This Graph Mgt code unit is used to generate id fields for all
    // // sales docs other than invoice and order. If special logic is required
    // // for any of these sales docs, create a seperate code unit.


    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummySalesHeader: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        SalesHeaderRecordRef: RecordRef;
    begin
        SalesHeaderRecordRef.Open(DATABASE::"Sales Header");
        GraphMgtGeneralTools.UpdateIntegrationRecords(SalesHeaderRecordRef, DummySalesHeader.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [Scope('OnPrem')]
    procedure UpdateReferencedIdFieldOnSalesHeader(var RecRef: RecordRef; NewId: Guid; var Handled: Boolean)
    var
        DummySalesHeader: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not CheckSupportedTable(RecRef) then
            exit;

        GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, NewId, Handled,
          RecRef.Number, DummySalesHeader.FieldNo(Id));
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
        UpdateIds;
    end;

    local procedure CheckSupportedTable(var RecRef: RecordRef): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if RecRef.Number = DATABASE::"Sales Header" then begin
            RecRef.SetTable(SalesHeader);
            if ((SalesHeader."Document Type" = SalesHeader."Document Type"::"Blanket Order") or
                (SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order"))
            then
                exit(false);
            exit(true);
        end;
        exit(false);
    end;

    procedure UpdateIds()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        with SalesInvoiceEntityAggregate do begin
            if FindSet then
                repeat
                    UpdateReferencedRecordIds;
                    Modify(false);
                until Next = 0;
        end;
    end;
}

