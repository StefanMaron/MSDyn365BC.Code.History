codeunit 5707 "TransferOrder-Post + Print"
{
    TableNo = "Transfer Header";

    trigger OnRun()
    begin
        TransHeader.Copy(Rec);
        Code();
        Rec := TransHeader;
    end;

    var
        TransHeader: Record "Transfer Header";

        Text000: Label '&Ship,&Receive';

    local procedure "Code"()
    var
        TransLine: Record "Transfer Line";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled);
        if IsHandled then
            exit;

        DefaultNumber := 0;
        with TransHeader do begin
            TransLine.SetRange("Document No.", "No.");
            if TransLine.Find('-') then
                repeat
                    if (TransLine."Quantity Shipped" < TransLine.Quantity) and
                       (DefaultNumber = 0)
                    then
                        DefaultNumber := Selection::Shipment;
                    if (TransLine."Quantity Received" < TransLine.Quantity) and
                       (DefaultNumber = 0)
                    then
                        DefaultNumber := Selection::Receipt;
                until (TransLine.Next() = 0) or (DefaultNumber > 0);

            OnRunOnBeforePrepareAndPrintReport(TransHeader, DefaultNumber, Selection);

            if "Direct Transfer" then begin
                TransferPostShipment.Run(TransHeader);
                TransferPostReceipt.Run(TransHeader);
                PrintReport(TransHeader, Selection::Receipt);
            end else begin
                if DefaultNumber = 0 then
                    DefaultNumber := Selection::Shipment;
                Selection := StrMenu(Text000, DefaultNumber);
                case Selection of
                    0:
                        exit;
                    Selection::Shipment:
                        TransferPostShipment.Run(TransHeader);
                    Selection::Receipt:
                        TransferPostReceipt.Run(TransHeader);
                end;
                PrintReport(TransHeader, Selection);
            end;
        end;

        OnAfterPost(TransHeader, Selection);
    end;

    procedure PrintReport(TransHeaderSource: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
        with TransHeaderSource do
            case Selection of
                Selection::Shipment:
                    PrintShipment("Last Shipment No.");
                Selection::Receipt:
                    PrintReceipt("Last Receipt No.");
            end;
    end;

    local procedure PrintShipment(DocNo: Code[20])
    var
        TransShptHeader: Record "Transfer Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShipment(DocNo, IsHandled);
        if IsHandled then
            exit;

        if TransShptHeader.Get(DocNo) then begin
            TransShptHeader.SetRecFilter();
            TransShptHeader.PrintRecords(false);
        end;
    end;

    local procedure PrintReceipt(DocNo: Code[20])
    var
        TransRcptHeader: Record "Transfer Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceipt(DocNo, IsHandled);
        if IsHandled then
            exit;

        if TransRcptHeader.Get(DocNo) then begin
            TransRcptHeader.SetRecFilter();
            TransRcptHeader.PrintRecords(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceipt(DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShipment(DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePrepareAndPrintReport(var TransferHeader: Record "Transfer Header"; var DefaultNumber: Integer; var Selection: Option)
    begin
    end;
}

