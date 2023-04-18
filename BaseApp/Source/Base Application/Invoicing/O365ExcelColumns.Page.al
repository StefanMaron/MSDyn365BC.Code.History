#if not CLEAN21
page 2182 "O365 Excel Columns"
{
    Caption = 'O365 Excel Columns';
    Editable = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Column Number';
                    ToolTip = 'Specifies the Excel column number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
        Reset();
        DeleteAll();
        Copy(TempStarRowCellNameValueBuffer, true);
    end;
}
#endif
