codeunit 5476 "Graph Mgt - Sales Inv. Lines"
{

    trigger OnRun()
    begin
    end;

    procedure GetUnitOfMeasureJSON(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"): Text
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        UnitOfMeasureJSON: Text;
    begin
        if SalesInvoiceLineAggregate."No." = '' then
            exit;

        case SalesInvoiceLineAggregate.Type of
            SalesInvoiceLineAggregate.Type::Item:
                begin
                    if not Item.Get(SalesInvoiceLineAggregate."No.") then
                        exit;

                    UnitOfMeasureJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, SalesInvoiceLineAggregate."Unit of Measure Code");
                end;
            else
                UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON(SalesInvoiceLineAggregate."Unit of Measure Code");
        end;

        exit(UnitOfMeasureJSON);
    end;

    [Scope('Cloud')]
    procedure GetDocumentIdFilterFromIdFilter(IdFilter: Text): Text
    begin
        exit(CopyStr(IdFilter, 1, 36));
    end;

}

