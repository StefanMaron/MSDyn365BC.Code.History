page 5775 "Warehouse Setup"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Warehouse Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Require Receive"; "Require Receive")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether you require users to use the receive activity.';
                }
                field("Require Put-away"; "Require Put-away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether you require users to use the put-away activity.';
                }
                field("Require Shipment"; "Require Shipment")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if warehouse shipments are required in warehouse work flows.';
                }
                field("Require Pick"; "Require Pick")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether you require users to use the pick activity.';
                }
                field("Last Whse. Posting Ref. No."; "Last Whse. Posting Ref. No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the document reference of the last warehouse posting will be shown.';
                }
                field("Receipt Posting Policy"; "Receipt Posting Policy")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies what should happen if errors occur when warehouse receipts are posted.';
                }
                field("Shipment Posting Policy"; "Shipment Posting Policy")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies what should happen if errors occur when warehouse shipments are posted.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Whse. Receipt Nos."; "Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code to use when you assign numbers to warehouse receipt journals.';
                }
                field("Whse. Ship Nos."; "Whse. Ship Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse shipment journals.';
                }
                field("Whse. Internal Put-away Nos."; "Whse. Internal Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to internal put-always.';
                }
                field("Whse. Internal Pick Nos."; "Whse. Internal Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to internal picks.';
                }
                field("Whse. Put-away Nos."; "Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse put-away documents.';
                }
                field("Whse. Pick Nos."; "Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse pick documents.';
                }
                field("Posted Whse. Receipt Nos."; "Posted Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse receipts.';
                }
                field("Posted Whse. Shipment Nos."; "Posted Whse. Shipment Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse shipments.';
                }
                field("Registered Whse. Put-away Nos."; "Registered Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used when numbers are assigned to registered put-away documents.';
                }
                field("Registered Whse. Pick Nos."; "Registered Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want to be used to assign numbers to registered pick documents.';
                }
                field("Whse. Movement Nos."; "Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to warehouse movements.';
                }
                field("Registered Whse. Movement Nos."; "Registered Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to registered warehouse movements.';
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

