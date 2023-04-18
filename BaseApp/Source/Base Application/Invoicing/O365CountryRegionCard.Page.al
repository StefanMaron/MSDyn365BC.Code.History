#if not CLEAN21
page 2195 "O365 Country/Region Card"
{
    Caption = 'Country/Region';
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "O365 Country/Region";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field("Code"; Code)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ToolTip = 'Specifies the ISO code of the country or region.';
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ToolTip = 'Specifies the name of the country or region.';
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        O365SalesManagement.InsertNewCountryCode(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        O365SalesManagement.ModifyCountryCode(xRec, Rec);
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
}
#endif
