#if not CLEAN21
page 2149 "O365 Email CC/BCC Card"
{
    Caption = 'CC/BCC Email';
    PageType = Card;
    SourceTable = "O365 Email Setup";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Email; Email)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
#endif
