page 5880 "Phys. Inventory Recording List"
{
    ApplicationArea = Warehouse;
    Caption = 'Phys. Inventory Recording List';
    CardPageID = "Phys. Inventory Recording";
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Record Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the physical inventory header number that is linked to the physical inventory recording.';
                }
                field("Recording No."; "Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a number that is assigned to the physical inventory recording, when you link a physical inventory recording to a physical inventory order.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the inventory recording.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the physical inventory recording is open or finished.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person responsible for performing this physical inventory recording.';
                }
                field("Date Recorded"; "Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                }
                field("Time Recorded"; "Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when physical inventory was taken.';
                }
                field("Person Recorded"; "Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the User ID of the person who performed the physical inventory.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Physical Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Recording';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Phys. Invt. Recording";
                ToolTip = 'Prepare to count inventory by creating a recording document to capture the quantities.';
            }
        }
    }
}

