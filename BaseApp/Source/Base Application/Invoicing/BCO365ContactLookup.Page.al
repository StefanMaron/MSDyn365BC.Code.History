#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = NewCustomer;
                RunObject = Page "BC O365 Sales Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new customer.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(_NEW_TEMP__Promoted; _NEW_TEMP_)
                {
                }
            }
        }
    }
}
#endif
