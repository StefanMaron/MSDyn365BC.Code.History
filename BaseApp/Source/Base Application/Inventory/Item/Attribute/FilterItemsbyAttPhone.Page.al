namespace Microsoft.Inventory.Item.Attribute;

page 7509 "Filter Items by Att. Phone"
{
    Caption = 'Filter Items by Attribute';
    DataCaptionExpression = '';
    PageType = List;
    SourceTable = "Filter Item Attributes Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Attribute; Rec.Attribute)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Item Attribute".Name;
                    ToolTip = 'Specifies the name of the attribute to filter on.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the value of the filter. You can use single values or filter expressions, such as >,<,>=,<=,|,&, and 1..100.';

                    trigger OnAssistEdit()
                    begin
                        Rec.ValueAssistEdit();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Rec.SetRange(Value, '');
        Rec.DeleteAll();
    end;
}

