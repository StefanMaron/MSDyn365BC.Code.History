page 18872 "TCS Journal Template List"
{
    Caption = 'TCS Journal Template List';
    Editable = false;
    PageType = List;
    SourceTable = "TCS Journal Template";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal template you are creating.';
                }
            }
        }
    }
}