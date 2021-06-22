page 2182 "O365 Excel Columns"
{
    Caption = 'O365 Excel Columns';
    Editable = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Column Number';
                    ToolTip = 'Specifies the Excel column number.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Cell Value';
                    ToolTip = 'Specifies the Excel cell value.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetStartRowCellBuffer(var TempStarRowCellNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        Reset;
        DeleteAll();
        Copy(TempStarRowCellNameValueBuffer, true);
    end;
}

