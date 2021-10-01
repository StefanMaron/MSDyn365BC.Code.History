#if not CLEAN19
page 991 "Query Nav. Page Lookup"
{
    PageType = List;
    Editable = false;
    Extensible = false;
    SourceTable = "Page Metadata";
    Caption = 'Select Target Page';
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

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
#endif