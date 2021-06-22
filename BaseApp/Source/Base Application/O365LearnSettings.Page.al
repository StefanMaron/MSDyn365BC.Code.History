page 2131 "O365 Learn Settings"
{
    Caption = 'Learn';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the learn setting.';
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenLink;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems;
    end;

    var
        ThirdPartyNoticeTitleLbl: Label 'Third party notice';
        ThirdPartyNoticeDescriptionLbl: Label 'View the third party notice.';
        PrivacyTitleLbl: Label 'Privacy';
        PrivacyDescriptionLbl: Label 'View the privacy statement.';
        SoftwareLicenseTitleLbl: Label 'Software license terms';
        SoftwareLicenseDescriptionLbl: Label 'View the software license terms.';

    local procedure InsertMenuItems()
    begin
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831306', ThirdPartyNoticeTitleLbl, ThirdPartyNoticeDescriptionLbl);
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831304', SoftwareLicenseTitleLbl, SoftwareLicenseDescriptionLbl);
        InsertHyperlinkMenuItem(
          'https://go.microsoft.com/fwlink/?linkid=831305', PrivacyTitleLbl, PrivacyDescriptionLbl);
    end;
}

