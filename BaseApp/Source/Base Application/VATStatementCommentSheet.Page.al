#if not CLEAN17
page 11770 "VAT Statement Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'VAT Statement Comment Sheet (Obsolete)';
    DataCaptionFields = "VAT Statement Template Name", "VAT Statement Name";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "VAT Statement Comment Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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


#endif