page 2179 "O365 Contact Lookup"
{
    Caption = 'Select';
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Contact;
    SourceTableView = SORTING(Name);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(_NEW_TEMP_WEB)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = "Invoicing-New";
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                RunObject = Page "BC O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new Customer.';
                Visible = NOT IsPhone;
            }
            action(_NEW_TEMP_MOBILE)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = "Invoicing-New";
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                RunObject = Page "O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new Customer.';
                Visible = IsPhone;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsPhone := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        IsPhone: Boolean;
}

