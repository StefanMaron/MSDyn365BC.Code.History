page 990 "Query Nav. DataItem Lookup"
{
    PageType = List;
    Editable = false;
    Extensible = false;
    SourceTable = "Designed Query Data Item";
    Caption = 'Select Linking Data Item';

    layout
    {
        area(Content)
        {
            repeater(DataItems)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the data item.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the data item.';
                }
            }
        }
    }
}