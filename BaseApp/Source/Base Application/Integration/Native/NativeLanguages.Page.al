#if not CLEAN20
page 2870 "Native - Languages"
{
    Caption = 'Native - Languages';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Windows Language";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(languageId; "Language ID")
                {
                    ApplicationArea = All;
                    Caption = 'languageId', Locked = true;
                }
                field(languageCode; LanguageCode)
                {
                    ApplicationArea = All;
                    Caption = 'languageCode';
                    Editable = false;
                    ToolTip = 'Specifies the language code.';
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(default; Default)
                {
                    ApplicationArea = All;
                    Caption = 'default';
                    Editable = false;
                    ToolTip = 'Specifies if the language is the default.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        UserPersonalization: Record "User Personalization";
        Language: Codeunit Language;
        CultureInfo: DotNet CultureInfo;
        DefaultLanguageId: Integer;
    begin
        CultureInfo := CultureInfo.CultureInfo("Language ID");
        LanguageCode := CultureInfo.Name;
        Default := false;
        DefaultLanguageId := Language.GetDefaultApplicationLanguageId();

        if UserPersonalization.Get(UserSecurityId()) and (UserPersonalization."Language ID" > 0) then
            DefaultLanguageId := UserPersonalization."Language ID";

        if "Language ID" = DefaultLanguageId then
            Default := true;
    end;

    trigger OnOpenPage()
    var
        Language: Codeunit Language;
    begin
        Language.GetApplicationLanguages(Rec);
    end;

    var
        LanguageCode: Text;
        Default: Boolean;
}
#endif
