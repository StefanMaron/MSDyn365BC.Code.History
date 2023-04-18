#if not CLEAN21
page 2136 "O365 Help Feedback Settings"
{
    Caption = 'Help & Feedback';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the help setting.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenLink();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems();
    end;

    var
        HelpTitleLbl: Label 'Help';
        HelpDescriptionLbl: Label 'Learn more about invoicing.';
        FeedbackTitleLbl: Label 'Feedback';
        FeedbackDescriptionLbl: Label 'Help us improve invoicing.';
        ThirdPartyNoticeTitleLbl: Label 'Third party notice';
        ThirdPartyNoticeDescriptionLbl: Label 'View the third party notice.';
        PrivacyTitleLbl: Label 'Privacy';
        PrivacyDescriptionLbl: Label 'View the privacy statement.';
        SoftwareLicenseTitleLbl: Label 'Software license terms';
        SoftwareLicenseDescriptionLbl: Label 'View the software license terms.';

    local procedure InsertMenuItems()
    begin
        InsertHyperlinkMenuItem('https://aka.ms/invoicinggetstarted', HelpTitleLbl, HelpDescriptionLbl);
        InsertHyperlinkMenuItem('https://aka.ms/smbinvoicefeedback', FeedbackTitleLbl, FeedbackDescriptionLbl);
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831306', ThirdPartyNoticeTitleLbl, ThirdPartyNoticeDescriptionLbl);
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831304', SoftwareLicenseTitleLbl, SoftwareLicenseDescriptionLbl);
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831305', PrivacyTitleLbl, PrivacyDescriptionLbl);
    end;
}
#endif
