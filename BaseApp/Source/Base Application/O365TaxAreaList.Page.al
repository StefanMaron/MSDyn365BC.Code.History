#if not CLEAN21
page 2151 "O365 Tax Area List"
{
    Caption = 'Tax Rates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Tax Area";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; GetDescriptionInCurrentLanguageFullLength())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Name';
                }
            }
        }
    }

    actions
    {
    }
}
#endif
