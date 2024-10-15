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
        area(processing)
        {
            action(New)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                RunObject = Page "BC O365 Tax Settings Card";
                RunPageMode = Create;
                ToolTip = 'Add a new tax rate.';
                Visible = NOT IsCanada;
            }
            action(Edit)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"BC O365 Tax Settings Card", Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(New_Promoted; New)
                {
                }
                actionref(Edit_Promoted; Edit)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        IsCanada := O365SalesInvoiceMgmt.IsCountryCanada();
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        IsCanada: Boolean;
}
#endif
