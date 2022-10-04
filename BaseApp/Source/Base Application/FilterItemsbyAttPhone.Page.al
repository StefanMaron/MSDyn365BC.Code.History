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
                field(Attribute; Attribute)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Item Attribute".Name;
                    ToolTip = 'Specifies the name of the attribute to filter on.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the value of the filter. You can use single values or filter expressions, such as >,<,>=,<=,|,&, and 1..100.';

                    trigger OnAssistEdit()
                    begin
                        ValueAssistEdit();
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
        SetRange(Value, '');
        DeleteAll();
    end;
}

