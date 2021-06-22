page 99000768 "Manufacturing Setup"
{
    ApplicationArea = Manufacturing, Planning;
    Caption = 'Manufacturing Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Manufacturing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Normal Starting Time"; "Normal Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the normal starting time of the workday.';
                }
                field("Normal Ending Time"; "Normal Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the normal ending time of a workday.';
                }
                field("Preset Output Quantity"; "Preset Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies what to show in the Output Quantity field of a production journal when it is first opened.';
                }
                field("Show Capacity In"; "Show Capacity In")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies which capacity unit of measure to use by default to record and track capacity.';
                }
                field("Planning Warning"; "Planning Warning")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to run the MRP engine to detect if planned shipment dates cannot be met.';
                }
                field("Doc. No. Is Prod. Order No."; "Doc. No. Is Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the production order number is also the document number in the ledger entries posted for the production order.';
                }
                field("Dynamic Low-Level Code"; "Dynamic Low-Level Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies low-level codes are dynamically assigned to each component in a product structure. Note that this may affect performance. The top final assembly level is denoted as level 0, the end item. The higher the low-level code number, the lower the item is in the hierarchy. The codes are used in the planning of component parts. When you calculate a plan, the BOM is exploded in the planning worksheet, and the gross requirements for level 0 are passed down the planning levels as gross requirements for the next planning level.';
                }
                field("Cost Incl. Setup"; "Cost Incl. Setup")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether the setup times are to be included in the cost calculation of the Standard Cost field.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Simulated Order Nos."; "Simulated Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a simulated production order.';
                }
                field("Planned Order Nos."; "Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a planned production order.';
                }
                field("Firm Planned Order Nos."; "Firm Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to firm planned production orders.';
                }
                field("Released Order Nos."; "Released Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a released production order.';
                }
                field("Work Center Nos."; "Work Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to work centers.';
                }
                field("Machine Center Nos."; "Machine Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to machine centers.';
                }
                field("Production BOM Nos."; "Production BOM Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to production BOMs.';
                }
                field("Routing Nos."; "Routing Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to routings.';
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                field("Current Production Forecast"; "Current Production Forecast")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the relevant demand forecast to use to calculate a plan.';
                }
                field("Use Forecast on Locations"; "Use Forecast on Locations")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies that actual demand for the selected demand forecast is nettet for the specified location only. If you leave the check box empty, the program regards the demand forecast as valid for all locations.';
                }
                field("Default Safety Lead Time"; "Default Safety Lead Time")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies a time period that is added to the lead time of all items that do not have another value specified in the Safety Lead Time field.';
                }
                field("Blank Overflow Level"; "Blank Overflow Level")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how the planning system should react if the Overflow Level field on the item or SKU card is empty.';
                }
                field("Combined MPS/MRP Calculation"; "Combined MPS/MRP Calculation")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies if both master production schedule and material requirements plan are run when you choose the Calc. Regenerative Plan action in the planning worksheet.';
                }
                field("Components at Location"; "Components at Location")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies the inventory location from where the production order components are to be taken.';
                }
                field("Default Dampener Period"; "Default Dampener Period")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward.';
                }
                field("Default Dampener %"; "Default Dampener %")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a percentage of an item''s lot size by which an existing supply must change before a planning suggestion is made.';
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

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

