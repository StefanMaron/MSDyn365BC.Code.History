codeunit 5528 "Graph Mgt - Purch. Inv. Lines"
{

    trigger OnRun()
    begin
    end;

    procedure GetUnitOfMeasureJSON(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"): Text
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        UnitOfMeasureJSON: Text;
    begin
        if PurchInvLineAggregate."No." = '' then
            exit;

        case PurchInvLineAggregate.Type of
            PurchInvLineAggregate.Type::Item:
                begin
                    if not Item.Get(PurchInvLineAggregate."No.") then
                        exit;

                    UnitOfMeasureJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, PurchInvLineAggregate."Unit of Measure Code");
                end;
            else
                UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON(PurchInvLineAggregate."Unit of Measure Code");
        end;

        exit(UnitOfMeasureJSON);
    end;
}

