codeunit 5932 "Service-Get Shipment"
{
    TableNo = "Service Line";

    trigger OnRun()
    begin
        ServiceHeader.Get("Document Type", "Document No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);

        Clear(ServiceShptLine);
        ServiceShptLine.SetCurrentKey("Bill-to Customer No.");
        ServiceShptLine.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        ServiceShptLine.SetRange("Currency Code", ServiceHeader."Currency Code");
        OnAfterSetServiceShptLineFilters(ServiceShptLine);
        ServiceShptLine.FilterGroup(2);

        GetServiceShipments.SetTableView(ServiceShptLine);
        GetServiceShipments.SetServiceHeader(ServiceHeader);
        GetServiceShipments.LookupMode(true);
        GetServiceShipments.RunModal;
    end;

    var
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceShptLine: Record "Service Shipment Line";
        GetServiceShipments: Page "Get Service Shipment Lines";

    procedure CreateInvLines(var ServiceShptLine2: Record "Service Shipment Line")
    var
        TransferLine: Boolean;
    begin
        with ServiceShptLine2 do begin
            SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if Find('-') then begin
                ServiceLine.LockTable();
                ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                ServiceLine."Document Type" := ServiceHeader."Document Type";
                ServiceLine."Document No." := ServiceHeader."No.";
                repeat
                    if ServiceShptHeader."No." <> "Document No." then begin
                        ServiceShptHeader.Get("Document No.");
                        TransferLine := true;
                        if ServiceShptHeader."Currency Code" <> ServiceHeader."Currency Code" then begin
                            Message(
                              Text001,
                              ServiceHeader.FieldCaption("Currency Code"),
                              ServiceHeader.TableCaption, ServiceHeader."No.",
                              ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                            TransferLine := false;
                        end;
                        if ServiceShptHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No." then begin
                            Message(
                              Text001,
                              ServiceHeader.FieldCaption("Bill-to Customer No."),
                              ServiceHeader.TableCaption, ServiceHeader."No.",
                              ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                            TransferLine := false;
                        end;
                    end;
                    if TransferLine then begin
                        ServiceShptLine := ServiceShptLine2;
                        ServiceShptLine.InsertInvLineFromShptLine(ServiceLine);
                    end;
                until Next = 0;
                OnAfterCreateInvLines(ServiceHeader);
            end;
        end;
    end;

    procedure SetServiceHeader(var ServiceHeader2: Record "Service Header")
    begin
        ServiceHeader.Get(ServiceHeader2."Document Type", ServiceHeader2."No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceShptLineFilters(var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;
}

