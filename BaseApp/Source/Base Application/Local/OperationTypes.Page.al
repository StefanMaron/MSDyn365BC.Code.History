page 12144 "Operation Types"
{
    Caption = 'Operation Types';
    Editable = false;
    PageType = List;
    SourceTable = "No. Series";
    SourceTableView = WHERE("No. Series Type" = FILTER(Sales | Purchase));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the type of operation.';
                }
                field("No. Series Type"; Rec."No. Series Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series type that is associated with the number series code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }

    actions
    {
    }
}

