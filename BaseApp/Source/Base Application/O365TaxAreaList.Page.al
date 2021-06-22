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

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; GetDescriptionInCurrentLanguage)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Name';
                }
            }
        }
    }

    actions
    {
    }
}

