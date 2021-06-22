page 6078 "Service Contract Line List"
{
    Caption = 'Service Contract Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item that is subject to the service contract.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the service item that is subject to the contract.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item that is subject to the contract.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item linked to the service item in the service contract.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Response Time (Hours)"; "Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service item associated with the service contract.';
                }
                field("Line Value"; "Line Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of the service item line in the contract or contract quote.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Service Period"; "Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the period of time that must pass between each servicing of an item.';
                }
                field("Next Planned Service Date"; "Next Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the next planned service on the item included in the contract.';
                }
                field("Last Planned Service Date"; "Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last planned service on this item.';
                }
                field("Last Preventive Maint. Date"; "Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the last time preventative service was performed on this item.';
                }
                field("Last Service Date"; "Last Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service item on the line was last serviced.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Contract Expiration Date"; "Contract Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when an item should be removed from the contract.';
                }
                field("Credit Memo Date"; "Credit Memo Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you can create a credit memo for the service item that needs to be removed from the service contract.';
                }
                field("New Line"; "New Line")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the service contract line is new or existing.';
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Service &Item Card")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Item Card';
                    Image = ServiceItem;
                    RunObject = Page "Service Item Card";
                    RunPageLink = "No." = FIELD("Service Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the service item.';
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = FIELD("Service Item No.");
                    RunPageView = SORTING("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
            }
        }
    }
}

