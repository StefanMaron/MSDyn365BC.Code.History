page 10698 "VAT Notes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Notes';
    PageType = List;
    SourceTable = "VAT Note";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code.';
                }
                field("VAT Report Value"; Rec."VAT Report Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a values that will be used for the electronic VAT return submission.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }
}