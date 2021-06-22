page 5941 "Repair Status Setup"
{
    ApplicationArea = Service;
    Caption = 'Repair Status Setup';
    PageType = List;
    SourceTable = "Repair Status";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the repair status.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the repair status.';
                }
                field("Service Order Status"; "Service Order Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status that is linked to this repair status.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order status.';
                }
                field(Initial; Initial)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that no service has been performed.';
                }
                field("In Process"; "In Process")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item is in process.';
                }
                field(Finished; Finished)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item has been finished.';
                }
                field("Partly Serviced"; "Partly Serviced")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service item has been partly serviced. Further work is needed.';
                }
                field(Referred; Referred)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item has been referred to another resource. No service has been performed on the service item.';
                }
                field("Spare Part Ordered"; "Spare Part Ordered")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a spare part has been ordered for the service item.';
                }
                field("Spare Part Received"; "Spare Part Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a spare part has been received for the service item.';
                }
                field("Waiting for Customer"; "Waiting for Customer")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you are waiting for a customer response.';
                }
                field("Quote Finished"; "Quote Finished")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that quoting work on the service item is finished.';
                }
                field("Posting Allowed"; "Posting Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can post a service order, if it includes a service item with this repair status.';
                }
                field("Pending Status Allowed"; "Pending Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to Pending, if it includes a service item with this repair status.';
                }
                field("In Process Status Allowed"; "In Process Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to In Process, if it includes a service item with this repair status.';
                }
                field("Finished Status Allowed"; "Finished Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to Finished, if it includes a service item with this repair status.';
                }
                field("On Hold Status Allowed"; "On Hold Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to On Hold, if it includes a service item with this repair status.';
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

