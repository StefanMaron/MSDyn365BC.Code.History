page 2379 "BC O365 Contact Lookup"
{
    Caption = 'Select';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = NewCustomer;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "BC O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new customer.';
            }
        }
    }
}

