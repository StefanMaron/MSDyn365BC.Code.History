#if not CLEAN21
page 2179 "O365 Contact Lookup"
{
    Caption = 'Select';
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Contact;
    SourceTableView = SORTING(Name);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = "Invoicing-New";
                RunObject = Page "BC O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new Customer.';
                Visible = NOT IsPhone;
            }
            action(_NEW_TEMP_MOBILE)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = "Invoicing-New";
                RunObject = Page "O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new Customer.';
                Visible = IsPhone;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(_NEW_TEMP_WEB_Promoted; _NEW_TEMP_WEB)
                {
                }
                actionref(_NEW_TEMP_MOBILE_Promoted; _NEW_TEMP_MOBILE)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsPhone := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        IsPhone: Boolean;
}
#endif
