page 5924 "Loaner Entries"
{
    ApplicationArea = Service;
    Caption = 'Loaner Entries';
    DataCaptionFields = "Loaner No.";
    Editable = false;
    PageType = List;
    SourceTable = "Loaner Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the document type of the entry is a quote or order.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service document specifying the service item you have replaced with the loaner.';
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item that you have replaced with the loaner.';
                }
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line for which you have lent the loaner.';
                }
                field("Loaner No."; "Loaner No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the loaner.';
                }
                field("Service Item Group Code"; "Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item group code of the service item that you have replaced with the loaner.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer to whom you have lent the loaner.';
                }
                field("Date Lent"; "Date Lent")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you lent the loaner.';
                }
                field("Time Lent"; "Time Lent")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you lent the loaner.';
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you received the loaner.';
                }
                field("Time Received"; "Time Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you received the loaner.';
                }
                field(Lent; Lent)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the loaner is lent.';
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
}

