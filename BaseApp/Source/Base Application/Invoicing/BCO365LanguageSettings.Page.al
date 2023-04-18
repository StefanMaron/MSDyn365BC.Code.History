#if not CLEAN21
page 2337 "BC O365 Language Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(Language; LanguageName)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Language';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the language that pages are shown in. You must sign out and then sign in again for the change to take effect.';

                    trigger OnAssistEdit()
                    var
                        UserPersonalization: Record "User Personalization";
                    begin
                        Language.LookupApplicationLanguageId(LanguageID);
                        LanguageName := Language.GetWindowsLanguageName(LanguageID);
                        with UserPersonalization do begin
                            Get(UserSecurityId());
                            if "Language ID" <> LanguageID then begin
                                Validate("Language ID", LanguageID);
                                Modify(true);
                                Message(ReSignInMsg);
                            end;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        UserPersonalization: Record "User Personalization";
    begin
        with UserPersonalization do begin
            Get(UserSecurityId());
            LanguageID := "Language ID";
        end;
        LanguageName := Language.GetWindowsLanguageName(LanguageID);
    end;

    var
        Language: Codeunit Language;
        LanguageID: Integer;
        ReSignInMsg: Label 'You must sign out and then sign in again for the change to take effect.', Comment = '"sign out" and "sign in" are the same terms as shown in the Business Central client.';
        LanguageName: Text;
}
#endif
