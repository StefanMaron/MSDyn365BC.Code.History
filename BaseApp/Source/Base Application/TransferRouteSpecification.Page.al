page 5748 "Transfer Route Specification"
{
    Caption = 'Trans. Route Spec.';
    PageType = Card;
    SourceTable = "Transfer Route";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("In-Transit Code"; "In-Transit Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
#if not CLEAN18                
                field("Gen. Bus. Post. Group Ship"; "Gen. Bus. Post. Group Ship")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies general bussiness posting group for items ship.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Gen. Bus. Post. Group Receive"; "Gen. Bus. Post. Group Receive")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies general bussiness posting group for itemsreceive.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
#endif                
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

    trigger OnClosePage()
    var
        CanBeDeleted: Boolean;
    begin
        CanBeDeleted := true;
        OnBeforeClosePage(Rec, CanBeDeleted);
        if CanBeDeleted then
            if Get("Transfer-from Code", "Transfer-to Code") then
                if ("Shipping Agent Code" = '') and
                   ("Shipping Agent Service Code" = '') and
                   ("In-Transit Code" = '')
                then
                    Delete;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePage(TransferRoute: Record "Transfer Route"; var CanBeDeleted: Boolean)
    begin
    end;
}

