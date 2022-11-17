codeunit 5368 "Int. Table Manual Subscribers"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnValidateBaseUnitOfMeasure', '', false, false)]
    local procedure HandleOnValidateBaseUnitOfMeasure(var ValidateBaseUnitOfMeasure: Boolean)
    begin
        ValidateBaseUnitOfMeasure := true;
    end;
}