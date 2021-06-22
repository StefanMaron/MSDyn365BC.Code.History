page 2149 "O365 Email CC/BCC Card"
{
    Caption = 'CC/BCC Email';
    PageType = Card;
    SourceTable = "O365 Email Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Email; Email)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ExtendedDatatype = EMail;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if RecipientType = RecipientType::CC then
            CurrPage.Caption := CCPageCaptionTxt
        else
            CurrPage.Caption := BCCPageCaptionTxt;
    end;

    var
        CCPageCaptionTxt: Label 'Enter CC email address';
        BCCPageCaptionTxt: Label 'Enter BCC email address';
}

