report 6036 "Create Contract Service Orders"
{
    ApplicationArea = Service;
    Caption = 'Create Contract Service Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = WHERE("Contract Type" = CONST(Contract), "Change Status" = CONST(Locked), Status = CONST(Signed));
            RequestFilterFields = "Contract No.";
            dataitem("Service Contract Line"; "Service Contract Line")
            {
                DataItemLink = "Contract Type" = FIELD("Contract Type"), "Contract No." = FIELD("Contract No.");
                DataItemTableView = WHERE("Service Period" = FILTER(<> ''));

                trigger OnAfterGetRecord()
                begin
                    if "Contract Expiration Date" <> 0D then begin
                        if "Contract Expiration Date" <= "Next Planned Service Date" then
                            CurrReport.Skip();
                    end else
                        if ("Service Contract Header"."Expiration Date" <> 0D) and
                           ("Service Contract Header"."Expiration Date" <= "Next Planned Service Date")
                        then
                            CurrReport.Skip();

                    Cust.Get("Service Contract Header"."Bill-to Customer No.");
                    if Cust.Blocked = Cust.Blocked::All then
                        CurrReport.Skip();

                    ServHeader.SetCurrentKey("Contract No.", Status, "Posting Date");
                    ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
                    ServHeader.SetRange("Contract No.", "Contract No.");
                    ServHeader.SetRange(Status, ServHeader.Status::Pending);

                    ServOrderExist := ServHeader.FindFirst();
                    if ServOrderExist then begin
                        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
                        ServItemLine.SetRange("Document No.", ServHeader."No.");
                        ServItemLine.SetRange("Contract No.", "Contract No.");
                        ServItemLine.SetRange("Contract Line No.", "Line No.");
                        OnBeforeFindServiceItemLineOnServiceContractLineAfterGetRecord(
                          ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
                        if ServItemLine.FindFirst() then
                            CurrReport.Skip();
                    end;
                    CreateOrAddToServOrder();
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate = 0D then
                        Error(Text002);
                    if EndDate < StartDate then
                        Error(Text003);

                    if StartDate <> 0D then
                        if EndDate - StartDate + 1 > ServMgtSetup."Contract Serv. Ord.  Max. Days" then
                            Error(
                              Text004,
                              ServMgtSetup.TableCaption());

                    SetRange("Next Planned Service Date", StartDate, EndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VerifyServiceContractHeader();
            end;

            trigger OnPostDataItem()
            begin
                OnServiceContractHeaderPostDataItem();
            end;

            trigger OnPreDataItem()
            begin
                OnServiceContractHeaderPreDataItem("Service Contract Header", "Service Contract Line", StartDate, EndDate, CreateServOrders);
                if CreateServOrders = CreateServOrders::"Print Only" then begin
                    Clear(ContrServOrdersTest);
                    ContrServOrdersTest.InitVariables(StartDate, EndDate);
                    ContrServOrdersTest.SetTableView("Service Contract Header");
                    ContrServOrdersTest.RunModal();
                    CurrReport.Break();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date for the period that you want to create contract service orders for. The batch job includes contracts with service items that have next planned service dates on or later than this date.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date for the period that you want to create contract service orders for. The batch job includes contracts with service items with next planned service date on or earlier than this date.';

                        trigger OnValidate()
                        begin
                            if EndDate < StartDate then
                                Error(Text003);
                        end;
                    }
                    field(CreateServiceOrders; CreateServOrders)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Create Service Order,Print Only';
                        ToolTip = 'Specifies the desired action relating to contract service orders.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ServMgtSetup.Get();
        if ServMgtSetup."Last Contract Service Date" <> 0D then
            StartDate := ServMgtSetup."Last Contract Service Date" + 1;
    end;

    trigger OnPostReport()
    begin
        if CreateServOrders = CreateServOrders::"Create Service Order" then begin
            ServMgtSetup.Get();
            ServMgtSetup."Last Contract Service Date" := EndDate;
            ServMgtSetup.Modify();

            if not HideDialog then
                if ServOrderCreated > 1 then
                    Message(Text000, ServOrderCreated)
                else
                    Message(Text001, ServOrderCreated)
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        Cust: Record Customer;
        ServItem: Record "Service Item";
        Salesperson: Record "Salesperson/Purchaser";
        ContrServOrdersTest: Report "Contr. Serv. Orders - Test";
        ServOrderCreated: Integer;
        StartDate: Date;
        EndDate: Date;
        CreateServOrders: Option "Create Service Order","Print Only";
        ServOrderExist: Boolean;
        HideDialog: Boolean;

        Text000: Label '%1 service orders were created.';
        Text001: Label '%1 service order was created.';
        Text002: Label 'You must fill in the ending date field.';
        Text003: Label 'The starting date is after the ending date.';
        Text004: Label 'The date range you have entered is a longer period than is allowed in the %1 table.';
        Text005: Label 'A service order cannot be created for contract no. %1 because customer no. %2 does not have a %3.';

    local procedure CreateOrAddToServOrder()
    var
        NextLineNo: Integer;
    begin
        ServHeader.Reset();
        ServHeader.SetCurrentKey("Contract No.", Status, "Posting Date");
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
        ServHeader.SetRange("Contract No.", "Service Contract Header"."Contract No.");
        ServHeader.SetRange(Status, ServHeader.Status::Pending);
        ServHeader.SetFilter("Order Date", '>=%1', "Service Contract Line"."Next Planned Service Date");
        OnBeforeFindServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
        if not ServHeader.FindFirst() then begin
            CreateServiceHeader(ServHeader, "Service Contract Header");
            ServOrderCreated := ServOrderCreated + 1;
        end;

        NextLineNo := 0;
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader."No.");
        if ServItemLine.FindLast() then
            NextLineNo := ServItemLine."Line No."
        else
            NextLineNo := 0;

        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader."No.");
        ServItemLine.SetRange("Contract No.", "Service Contract Line"."Contract No.");
        ServItemLine.SetRange("Contract Line No.", "Service Contract Line"."Line No.");
        OnBeforeFindServiceItemLineOnCreateServiceHeader(ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
        if not ServItemLine.FindFirst() then
            CreateServiceItemLine(ServHeader, "Service Contract Line", NextLineNo);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
        Clear(ServiceHeader);
        with ServiceHeader do begin
            Init();
            "Document Type" := "Document Type"::Order;
            OnBeforeInsertServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
            Insert(true);
            SetHideValidationDialog(true);
            "Contract No." := ServiceContractHeader."Contract No.";
            Validate("Order Date", "Service Contract Line"."Next Planned Service Date");
            Validate("Customer No.", ServiceContractHeader."Customer No.");
            Validate("Bill-to Customer No.", ServiceContractHeader."Bill-to Customer No.");
            "Default Response Time (Hours)" := ServiceContractHeader."Response Time (Hours)";
            Validate("Ship-to Code", ServiceContractHeader."Ship-to Code");
            "Service Order Type" := ServiceContractHeader."Service Order Type";
            Validate("Currency Code", ServiceContractHeader."Currency Code");
            SetSalespersonCode(ServiceContractHeader."Salesperson Code", "Salesperson Code");
            "Max. Labor Unit Price" := ServiceContractHeader."Max. Labor Unit Price";
            "Your Reference" := ServiceContractHeader."Your Reference";
            "Service Zone Code" := ServiceContractHeader."Service Zone Code";
            "Shortcut Dimension 1 Code" := ServiceContractHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServiceContractHeader."Shortcut Dimension 2 Code";
            Validate("Service Order Type", ServiceContractHeader."Service Order Type");
            "Dimension Set ID" := ServiceContractHeader."Dimension Set ID";
            OnBeforeModifyServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
            Modify(true);
        end;
        OnAfterCreateServiceHeader(ServiceHeader, ServiceContractHeader);
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header"; ServiceContractLine: Record "Service Contract Line"; var NextLineNo: Integer)
    var
        RepairStatus: Record "Repair Status";
    begin
        with ServItemLine do begin
            Init();
            SetHideDialogBox(true);
            "Document No." := ServiceHeader."No.";
            "Document Type" := ServiceHeader."Document Type";
            RepairStatus.Reset();
            RepairStatus.Initial := true;
            "Repair Status Code" := RepairStatus.ReturnStatusCode(RepairStatus);
            NextLineNo := NextLineNo + 10000;
            "Line No." := NextLineNo;
            if "Service Contract Line"."Service Item No." <> '' then begin
                ServItem.Get("Service Contract Line"."Service Item No.");
                Validate("Service Item No.", ServItem."No.");
                "Location of Service Item" := ServItem."Location of Service Item";
                Priority := ServItem.Priority;
            end else
                Description := "Service Contract Line".Description;
            "Serial No." := "Service Contract Line"."Serial No.";
            "Item No." := "Service Contract Line"."Item No.";
            "Variant Code" := "Service Contract Line"."Variant Code";
            "Contract No." := "Service Contract Line"."Contract No.";
            "Contract Line No." := "Service Contract Line"."Line No.";
            UpdateResponseTimeHours();
            OnBeforeInsertServiceItemLine(ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
            Insert(true);
        end;

        OnAfterInsertServItemLine(ServItemLine, ServiceContractLine);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure InitializeRequest(StartDateFrom: Date; EndDateFrom: Date; CreateServOrdersFrom: Option)
    begin
        StartDate := StartDateFrom;
        EndDate := EndDateFrom;
        CreateServOrders := CreateServOrdersFrom;
    end;

    local procedure VerifyServiceContractHeader()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        with "Service Contract Header" do
            if "Ship-to Code" <> '' then
                if not ShipToAddress.Get("Customer No.", "Ship-to Code") then begin
                    Message(Text005, "Contract No.", "Customer No.", "Ship-to Code");
                    CurrReport.Skip();
                end;
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck <> '' then
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    SalesPersonCodeToAssign := ''
                else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderPreDataItem(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; StartDate: Date; EndDate: Date; CreateServOrders: Option "Create Service Order","Print Only")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderPostDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceItemLineOnServiceContractLineAfterGetRecord(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceItemLineOnCreateServiceHeader(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

