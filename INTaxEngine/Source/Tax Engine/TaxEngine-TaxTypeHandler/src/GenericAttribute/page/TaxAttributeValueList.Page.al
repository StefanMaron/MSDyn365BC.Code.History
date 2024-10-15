page 20236 "Tax Attribute Value List"
{
    DelayedInsert = true;
    Caption = 'Attribute Values';
    PageType = ListPart;
    SourceTableTemporary = true;
    LinksAllowed = false;
    SourceTable = "Tax Attribute Value Selection";

    layout
    {
        area(Content)
        {
            repeater(Group1)
            {
                field("Attribute Name"; "Attribute Name")
                {
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the attribute.';
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Tax Attribute".Name;
                    AssistEdit = false;

                    trigger OnValidate();

                    var
                        GenericAttributeValue: Record "Tax Attribute Value";
                    begin
                        if xRec."Attribute Name" <> '' then
                            DeleteAttributeValueMapping(xRec."Attribute ID");

                        if not FindAttributeValue(GenericAttributeValue) then
                            InsertAttributeValue(GenericAttributeValue, Rec);
                    end;
                }
                field(Value; Value)
                {
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the attribute.';
                    ApplicationArea = Basic, Suite;
                    TableRelation = if ("Attribute Type" = CONST(Option)) "Tax Attribute Value".Value WHERE("Attribute ID" = Field("Attribute ID"));

                    trigger OnValidate();

                    var
                        GenericAttributeValue: Record "Tax Attribute Value";
                    begin
                        if not FindAttributeValue(GenericAttributeValue) then
                            InsertAttributeValue(GenericAttributeValue, Rec);

                        if FindAttributeValueFromRecord(GenericAttributeValue, xRec) then
                            if not GenericAttributeValue.HasBeenUsed() then
                                GenericAttributeValue.Delete();
                    end;
                }
            }
        }
    }
    local procedure DeleteAttributeValueMapping(AttributeToDeleteID: Integer);

    var
        GenericAttribute: Record "Tax Attribute";
    begin
        GenericAttribute.SetRange(ID, AttributeToDeleteID);
        GenericAttribute.FindFirst();
        GenericAttribute.Delete();
        GenericAttribute.RemoveUnusedArbitraryValues();
    end;

    trigger OnOpenPage();
    begin
        CurrPage.EDITABLE(true);
    end;

    trigger OnDeleteRecord(): Boolean;
    begin
        DeleteAttributeValueMapping("Attribute ID");
    end;
}