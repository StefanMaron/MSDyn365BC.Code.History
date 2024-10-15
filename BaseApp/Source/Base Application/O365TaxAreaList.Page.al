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
                field(Name; GetDescriptionInCurrentLanguageFullLength())
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Name';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "BC O365 Tax Settings Card";
                RunPageMode = Create;
                ToolTip = 'Add a new tax rate.';
                Visible = NOT IsCanada;
            }
            action(Edit)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                Image = Edit;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"BC O365 Tax Settings Card", Rec);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        IsCanada := O365SalesInvoiceMgmt.IsCountryCanada;
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        IsCanada: Boolean;
}
