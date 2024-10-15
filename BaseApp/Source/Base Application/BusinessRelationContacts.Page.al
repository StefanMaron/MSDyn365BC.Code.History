page 5062 "Business Relation Contacts"
{
    Caption = 'Business Relation Contacts';
    DataCaptionFields = "Business Relation Code";
    PageType = List;
    SourceTable = "Contact Business Relation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact number of the company you are assigning a business relation.';
                }
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact company to which you assign a business relation. This field is not editable.';
                }
                field("Link to Table"; "Link to Table")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the name of the table to which the contact is linked. There are four possible options: &lt;blank&gt;, Vendor, Customer, and Bank Account.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.")
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.")
    end;

    trigger OnModifyRecord(): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.")
    end;
}

