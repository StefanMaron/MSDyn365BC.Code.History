page 36628 "Sales Order Invoice List"
{
    Caption = 'Sales Order Invoicing';
    CardPageID = "Sales Order Invoice";
    DataCaptionFields = "Document Type";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Order));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ToolTip = 'Specifies the number of the customer that you invoiced the items to.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ToolTip = 'Specifies the name of the customer that you invoiced the items to.';
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document. You can fill this field to use it later to search for sales lines using the customer''s order number.';
                }
                field("Location Code"; "Location Code")
                {
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
            }
        }
    }

    actions
    {
    }
}

