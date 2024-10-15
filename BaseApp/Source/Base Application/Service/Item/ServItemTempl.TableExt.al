namespace Microsoft.Inventory.Item;

using Microsoft.Service.Item;

tableextension 6453 "Serv. Item Templ." extends "Item Templ."
{
    fields
    {
        field(5900; "Service Item Group"; Code[10])
        {
            Caption = 'Service Item Group';
            DataClassification = CustomerContent;
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Service Item Group"));
            end;
        }
    }
}