page 11770 "VAT Statement Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'VAT Statement Comment Sheet';
    DataCaptionFields = "VAT Statement Template Name", "VAT Statement Name";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "VAT Statement Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1220002)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of VAT statement comment sheet.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for VAT statement.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Date := WorkDate;
    end;
}

