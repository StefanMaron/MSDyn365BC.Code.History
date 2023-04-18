#if not CLEAN20
page 581 "XBRL Line Constants Part"
{
    Caption = 'XBRL Line Constants Part';
    PageType = ListPart;
    SourceTable = "XBRL Line Constant";
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the date on which the constant amount on this line comes into effect. The constant amount on this line applies from this date until the date in the Starting Date field on the next line.';
                }
                field("Constant Amount"; Rec."Constant Amount")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the amount that is exported for this line, from the date in the Starting Date field until a new constant amount comes into effect, if the source type of the XBRL taxonomy line is Constant.';
                }
            }
        }
    }

    actions
    {
    }
}


#endif