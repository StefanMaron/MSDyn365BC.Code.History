#if not CLEAN20
page 2842 "Native - Email Setting"
{
    Caption = 'nativeEmailSetup', Locked = true;
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "O365 Email Setup";
    SourceTableView = SORTING(Email, RecipientType)
                      ORDER(Ascending);
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                    Editable = false;
                }
                field(recipientType; RecipientType)
                {
                    ApplicationArea = All;
                    Caption = 'recipientType', Locked = true;
                }
                field(eMail; Email)
                {
                    ApplicationArea = All;
                    Caption = 'eMail';

                    trigger OnValidate()
                    var
                        dnRegex: DotNet Regex;
                        dnMatch: DotNet Match;
                    begin
                        dnMatch := dnRegex.Match(Email, EmailValidatorRegexTxt);
                        if not dnMatch.Success then
                            Error(EmailInvalidErr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        EmailValidatorRegexTxt: Label '^[A-Z0-9a-z._%+-]+@(?:[A-Za-z0-9.-]+\.)+[A-Za-z]{2,64}$', Locked = true;
        EmailInvalidErr: Label 'Invalid Email Address.';
}
#endif
