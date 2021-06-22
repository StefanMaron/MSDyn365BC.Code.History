page 99000884 "Create Order From Sales"
{
    Caption = 'Create Order From Sales';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to create production orders for this sales order?';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field(Status; CreateStatus)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order Status';

                trigger OnValidate()
                begin

                end;
            }
            field(OrderType; OrderType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Order Type';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CreateStatus := CreateStatus::"Firm Planned";
        OrderStatus := CreateStatus;
    end;

    var
        OrderStatus: Enum "Production Order Status";
        CreateStatus: Enum "Create Production Order Status";
        OrderType: Enum "Create Production Order Type";

#if not CLEAN18
    [Obsolete('Replaced by GetParameters().', '18.0')]
    procedure ReturnPostingInfo(var NewStatus: Option Simulated,Planned,"Firm Planned",Released; var NewOrderType: Option ItemOrder,ProjectOrder)
    begin
        NewStatus := OrderStatus.AsInteger();
        NewOrderType := OrderType.AsInteger();
    end;
#endif

    procedure GetParameters(var NewStatus: Enum "Production Order Status"; var NewOrderType: Enum "Create Production Order Type")
    begin
        NewStatus := CreateStatus;
        NewOrderType := OrderType;
    end;

#if not CLEAN18
    [Obsolete('Replaced by SetParameters().', '18.0')]
    procedure SetPostingInfo(NewStatus: Option Simulated,Planned,"Firm Planned",Released; NewOrderType: Option ItemOrder,ProjectOrder)
    begin
        OrderStatus := "Production Order Status".FromInteger(NewStatus);
        CreateStatus := OrderStatus;
        OrderType := "Create Production Order Type".FromInteger(NewOrderType);
    end;
#endif

    procedure SetParameters(NewStatus: Enum "Create Production Order Status"; NewOrderType: Enum "Create Production Order Type")
    begin
        OrderStatus := NewStatus;
        CreateStatus := OrderStatus;
        OrderType := NewOrderType;
    end;
}

