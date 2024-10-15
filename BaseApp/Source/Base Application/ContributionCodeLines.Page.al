page 12107 "Contribution Code Lines"
{
    Caption = 'Contribution Code Lines';
    DataCaptionFields = "Code", "Contribution Type";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Contribution Code Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the Social Security tax code.';
                }
                field("Social Security %"; "Social Security %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage that is used to calculate the Social Security tax amount.';
                }
                field("Free-Lance Amount %"; "Free-Lance Amount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Social Security Bracket Code"; "Social Security Bracket Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security bracket code that is applied to the contribution code.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(true);
    end;
}

