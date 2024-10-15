namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

page 2587 "Dim Corr Values Overview"
{
    PageType = List;
    SourceTable = "Dimension Value";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    Caption = 'Dimension Values';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(DimCode; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the identifier of Dimension Value.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of dimension value.';
                }
            }
        }
    }
}