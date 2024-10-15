page 11771 "VAT Statement Attachment Sheet"
{
    AutoSplitKey = true;
    Caption = 'VAT Statement Attachment Sheet (Obsolete)';
    DataCaptionFields = "VAT Statement Template Name", "VAT Statement Name";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "VAT Statement Attachment";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of VAT statement attachment sheet.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the VAT statement attachment list.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name and address of the attachment file created for VAT statement.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Attachments")
            {
                Caption = '&Attachments';
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    ToolTip = 'Allows to import the VAT statement attachment.';

                    trigger OnAction()
                    begin
                        if Import then
                            CurrPage.SaveRecord;
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Date := WorkDate;
    end;
}

