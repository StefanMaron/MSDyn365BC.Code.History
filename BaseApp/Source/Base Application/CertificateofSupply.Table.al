table 780 "Certificate of Supply"
{
    Caption = 'Certificate of Supply';

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Sales Shipment,Service Shipment,Return Shipment';
            OptionMembers = "Sales Shipment","Service Shipment","Return Shipment";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Document Type" = FILTER("Sales Shipment")) "Sales Shipment Header"."No."
            ELSE
            IF ("Document Type" = FILTER("Service Shipment")) "Service Shipment Header"."No."
            ELSE
            IF ("Document Type" = FILTER("Return Shipment")) "Return Shipment Header"."No.";
        }
        field(3; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Not Applicable,Required,Received,Not Received';
            OptionMembers = "Not Applicable",Required,Received,"Not Received";

            trigger OnValidate()
            begin
                if xRec.Status = Status then
                    exit;

                if "No." = '' then
                    "No." := "Document No.";

                if Status = Status::Received then
                    "Receipt Date" := WorkDate
                else
                    "Receipt Date" := 0D;

                if Status = Status::"Not Applicable" then
                    "No." := ''
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if Status = Status::"Not Applicable" then begin
                    if "No." <> '' then
                        Error(NoCannotBeEnteredErr);
                end else
                    if "No." = '' then
                        Error(NoCannotBeEmptyErr)
            end;
        }
        field(5; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            begin
                CheckRcptDate
            end;
        }
        field(6; Printed; Boolean)
        {
            Caption = 'Printed';
        }
        field(7; "Customer/Vendor Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
            Editable = false;
        }
        field(8; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            Editable = false;
        }
        field(9; "Shipment/Posting Date"; Date)
        {
            Caption = 'Shipment/Posting Date';
            Editable = false;
        }
        field(10; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            Editable = false;
        }
        field(11; "Customer/Vendor No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
        }
        field(12; "Vehicle Registration No."; Text[20])
        {
            Caption = 'Vehicle Registration No.';

            trigger OnValidate()
            begin
                if (Status = Status::Received) and ("Vehicle Registration No." <> xRec."Vehicle Registration No.") then
                    Error(VehicleRegNoCannotBeChangedErr, FieldCaption("Vehicle Registration No."), Status::Received)
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecDateCannotBeEmptyErr: Label 'The Receipt Date cannot be empty when Status is Received.';
        RecDateCannotBeEnteredErr: Label 'You can enter the Receipt Date only if the status of the Certificate of Supply is Received.';
        CertRecDateBeforeShipmPostDateErr: Label 'The Receipt Date of the certificate cannot be earlier than the Shipment/Posting Date.';
        NoCannotBeEnteredErr: Label 'The No. field cannot be filled in when the status of the Certificate of Supply is set to Not Applicable.';
        NoCannotBeEmptyErr: Label 'The No. field cannot be empty when the status of the Certificate of Supply is set to Required, Received, or Not Received.';
        VehicleRegNoCannotBeChangedErr: Label 'The %1 field cannot be changed when the status of the Certificate of Supply is set to %2.';

    procedure Print()
    begin
        REPORT.RunModal(REPORT::"Certificate of Supply", true, false, Rec);
    end;

    procedure SetPrintedTrue()
    begin
        if Status = Status::"Not Applicable" then
            SetRequired("Document No.");
        Printed := true;

        Modify;
    end;

    procedure SetRequired(CertificateNo: Code[20])
    begin
        Status := Status::Required;
        "No." := CertificateNo;
        "Receipt Date" := 0D;
        Modify
    end;

    local procedure CheckRcptDate()
    begin
        if Status = Status::Received then begin
            if "Receipt Date" = 0D then
                Error(RecDateCannotBeEmptyErr);
            if "Shipment/Posting Date" > "Receipt Date" then
                Error(CertRecDateBeforeShipmPostDateErr);
        end else
            if "Receipt Date" <> 0D then
                Error(RecDateCannotBeEnteredErr);
    end;

    procedure InitFromSales(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        if not Get("Document Type"::"Sales Shipment", SalesShipmentHeader."No.") then begin
            Init;
            "Document Type" := "Document Type"::"Sales Shipment";
            "Document No." := SalesShipmentHeader."No.";
            "Customer/Vendor Name" := SalesShipmentHeader."Ship-to Name";
            "Shipment Method Code" := SalesShipmentHeader."Shipment Method Code";
            "Shipment/Posting Date" := SalesShipmentHeader."Shipment Date";
            "Ship-to Country/Region Code" := SalesShipmentHeader."Ship-to Country/Region Code";
            "Customer/Vendor No." := SalesShipmentHeader."Bill-to Customer No.";
            OnAfterInitFromSales(Rec, SalesShipmentHeader);
            Insert(true);
        end
    end;

    procedure InitFromPurchase(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        if not Get("Document Type"::"Return Shipment", ReturnShipmentHeader."No.") then begin
            Init;
            "Document Type" := "Document Type"::"Return Shipment";
            "Document No." := ReturnShipmentHeader."No.";
            "Customer/Vendor Name" := ReturnShipmentHeader."Ship-to Name";
            "Shipment Method Code" := ReturnShipmentHeader."Shipment Method Code";
            "Shipment/Posting Date" := ReturnShipmentHeader."Posting Date";
            "Ship-to Country/Region Code" := ReturnShipmentHeader."Ship-to Country/Region Code";
            "Customer/Vendor No." := ReturnShipmentHeader."Pay-to Vendor No.";
            OnAfterInitFromPurchase(Rec, ReturnShipmentHeader);
            Insert(true);
        end
    end;

    procedure InitFromService(var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        if not Get("Document Type"::"Service Shipment", ServiceShipmentHeader."No.") then begin
            Init;
            "Document Type" := "Document Type"::"Service Shipment";
            "Document No." := ServiceShipmentHeader."No.";
            "Customer/Vendor Name" := ServiceShipmentHeader."Ship-to Name";
            "Shipment Method Code" := '';
            "Shipment/Posting Date" := ServiceShipmentHeader."Posting Date";
            "Ship-to Country/Region Code" := ServiceShipmentHeader."Ship-to Country/Region Code";
            "Customer/Vendor No." := ServiceShipmentHeader."Bill-to Customer No.";
            OnAfterInitFromService(Rec, ServiceShipmentHeader);
            Insert(true);
        end
    end;

    procedure InitRecord(DocumentType: Option; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        case DocumentType of
            "Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(DocumentNo);
                    InitFromSales(SalesShipmentHeader);
                end;
            "Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(DocumentNo);
                    InitFromService(ServiceShipmentHeader);
                end;
            "Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(DocumentNo);
                    InitFromPurchase(ReturnShipmentHeader);
                end;
        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSales(var CertificateOfSupply: Record "Certificate of Supply"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchase(var CertificateOfSupply: Record "Certificate of Supply"; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromService(var CertificateOfSupply: Record "Certificate of Supply"; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;
}

