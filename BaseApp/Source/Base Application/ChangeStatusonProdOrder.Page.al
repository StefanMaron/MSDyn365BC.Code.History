page 99000882 "Change Status on Prod. Order"
{
    Caption = 'Change Status on Prod. Order';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to change the status of this production order?';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            field(FirmPlannedStatus; ProdOrderStatus.Status)
            {
                ApplicationArea = Manufacturing;
                Caption = 'New Status';
                ValuesAllowed = "Firm Planned", Released, Finished;

                trigger OnValidate()
                begin
                    case ProdOrderStatus.Status of
                        ProdOrderStatus.Status::Finished:
                            CheckStatus(FinishedStatusEditable);
                        ProdOrderStatus.Status::Released:
                            CheckStatus(ReleasedStatusEditable);
                        ProdOrderStatus.Status::"Firm Planned":
                            CheckStatus(FirmPlannedStatusEditable);
                    end;
                end;
            }
            field(PostingDate; PostingDate)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Posting Date';
            }
            field(ReqUpdUnitCost; ReqUpdUnitCost)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Update Unit Cost';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        FinishedStatusEditable := true;
        ReleasedStatusEditable := true;
        FirmPlannedStatusEditable := true;
    end;

    var
        ProdOrderStatus: Record "Production Order";
        PostingDate: Date;
        [InDataSet]
        FirmPlannedStatusEditable: Boolean;
        [InDataSet]
        ReleasedStatusEditable: Boolean;
        [InDataSet]
        FinishedStatusEditable: Boolean;
        Text666: Label '%1 is not a valid selection.';

    protected var
        ReqUpdUnitCost: Boolean;

    procedure Set(ProdOrder: Record "Production Order")
    begin
        if ProdOrder.Status = ProdOrder.Status::Finished then
            ProdOrder.FieldError(Status);

        FirmPlannedStatusEditable := ProdOrder.Status.AsInteger() < ProdOrder.Status::"Firm Planned".AsInteger();
        ReleasedStatusEditable := ProdOrder.Status <> ProdOrder.Status::Released;
        FinishedStatusEditable := ProdOrder.Status = ProdOrder.Status::Released;
        if ProdOrder.Status.AsInteger() > ProdOrder.Status::Simulated.AsInteger() then
            ProdOrderStatus.Status := "Production Order Status".FromInteger(ProdOrder.Status.AsInteger() + 1)
        else
            ProdOrderStatus.Status := ProdOrderStatus.Status::"Firm Planned";

        PostingDate := WorkDate;

        OnAfterSet(ProdOrder);
    end;

    procedure ReturnPostingInfo(var Status: Enum "Production Order Status"; var PostingDate2: Date; var UpdUnitCost: Boolean)
    begin
        Status := ProdOrderStatus.Status;
        PostingDate2 := PostingDate;
        UpdUnitCost := ReqUpdUnitCost;
    end;

    local procedure CheckStatus(StatusEditable: Boolean)
    begin
        if not StatusEditable then
            Error(Text666, ProdOrderStatus.Status);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterSet(ProdOrder: Record "Production Order")
    begin
    end;
}

