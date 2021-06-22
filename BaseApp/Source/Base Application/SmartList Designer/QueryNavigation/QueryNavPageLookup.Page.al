page 991 "Query Nav. Page Lookup"
{
    PageType = List;
    Editable = false;
    Extensible = false;
    SourceTable = "Page Metadata";
    Caption = 'Select Target Page';

    layout
    {
        area(Content)
        {
            repeater(Pages)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Specifies the ID of the page.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the page.';
                }

                field(Caption; Rec.Caption)
                {
                    ApplicationArea = All;
                    Caption = 'Caption';
                    ToolTip = 'Specifies the caption of the page.';
                }
            }
        }
    }
}