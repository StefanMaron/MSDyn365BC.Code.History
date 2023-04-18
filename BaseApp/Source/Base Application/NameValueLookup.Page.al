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
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
        if FindLast() then
            NextID := ID + 1
        else
            NextID := 1;

        Init();
        ID := NextID;
        Name := ItemName;
        Value := ItemValue;
        Insert();
    end;
}

