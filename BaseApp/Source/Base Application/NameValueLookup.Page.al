page 823 "Name/Value Lookup"
{
    Caption = 'Name/Value Lookup';
    Editable = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the value.';
                }
            }
        }
    }

    actions
    {
    }

    procedure AddItem(ItemName: Text[250]; ItemValue: Text[250])
    var
        NextID: Integer;
    begin
        LockTable();
        if FindLast then
            NextID := ID + 1
        else
            NextID := 1;

        Init;
        ID := NextID;
        Name := ItemName;
        Value := ItemValue;
        Insert;
    end;
}

