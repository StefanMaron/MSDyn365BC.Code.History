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
            field(Status; Status)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order Status';
                OptionCaption = ',Planned,Firm Planned,Released';
            }
            field(OrderType; OrderType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Order Type';
                OptionCaption = 'Item Order,Project Order';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Status := Status::"Firm Planned";
    end;

    var
        Status: Option Simulated,Planned,"Firm Planned",Released;
        OrderType: Option ItemOrder,ProjectOrder;

    procedure ReturnPostingInfo(var NewStatus: Option Simulated,Planned,"Firm Planned",Released; var NewOrderType: Option ItemOrder,ProjectOrder)
    begin
        NewStatus := Status;
        NewOrderType := OrderType;
    end;

    procedure SetPostingInfo(NewStatus: Option Simulated,Planned,"Firm Planned",Released; NewOrderType: Option ItemOrder,ProjectOrder)
    begin
        Status := NewStatus;
        OrderType := NewOrderType;
    end;
}

