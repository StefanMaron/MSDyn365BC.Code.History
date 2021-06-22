page 5390 "Product Item Availability"
{
    Caption = 'Product Item Availability';
    PageType = List;
    SourceTable = "CRM Integration Record";
    SourceTableView = WHERE("Table ID" = CONST(27));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("CRM ID"; "CRM ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the unique identifier (GUID) of the record in Dynamics 365 Sales that is coupled to a record in Business Central that is associated with the Integration ID.';
                }
                field("Integration ID"; "Integration ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the identifier (GUID) for a record that can be used by Dynamics 365 Sales to locate item records in Business Central.';
                    Visible = false;
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the table that the entry is stored in.';
                    Visible = false;
                }
                field(ItemNo; Item."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'ItemNo';
                    ToolTip = 'Specifies the item number.';
                }
                field(UOM; Item."Base Unit of Measure")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'UOM';
                    ToolTip = 'Specifies Unit of Measure';
                }
                field(Inventory; Item.Inventory)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies the inventory level of an item.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        IntegrationRecord: Record "Integration Record";
        RecordRef: RecordRef;
    begin
        Clear(Item);
        if IsNullGuid("Integration ID") or ("Table ID" <> DATABASE::Item) then
            exit;

        if IntegrationRecord.Get("Integration ID") then begin
            RecordRef.Get(IntegrationRecord."Record ID");
            RecordRef.SetTable(Item);
            Item.CalcFields(Inventory);
        end;
    end;

    var
        Item: Record Item;
}

