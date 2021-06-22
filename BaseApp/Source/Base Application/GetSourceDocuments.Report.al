report 5753 "Get Source Documents"
{
    Caption = 'Get Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Request"; "Warehouse Request")
        {
            DataItemTableView = WHERE("Document Status" = CONST(Released), "Completely Handled" = FILTER(false));
            RequestFilterFields = "Source Document", "Source No.";
            dataitem("Sales Header"; "Sales Header")
            {
                DataItemLink = "Document Type" = FIELD("Source Subtype"), "No." = FIELD("Source No.");
                DataItemTableView = SORTING("Document Type", "No.");
                dataitem("Sales Line"; "Sales Line")
                {
                    DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeSalesLineOnAfterGetRecord("Sales Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        VerifyItemNotBlocked("No.");
                        if "Location Code" = "Warehouse Request"."Location Code" then
                            case RequestType of
                                RequestType::Receive:
                                    if WhseActivityCreate.CheckIfSalesLine2ReceiptLine("Sales Line") then begin
                                        OnSalesLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                          "Sales Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateReceiptHeader;
                                            OnSalesLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Sales Header");
                                        end;
                                        if not WhseActivityCreate.SalesLine2ReceiptLine(WhseReceiptHeader, "Sales Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                                RequestType::Ship:
                                    if WhseActivityCreate.CheckIfFromSalesLine2ShptLine("Sales Line") then begin
                                        if Cust.Blocked <> Cust.Blocked::" " then begin
                                            if not SalesHeaderCounted then begin
                                                SkippedSourceDoc += 1;
                                                SalesHeaderCounted := true;
                                            end;
                                            CurrReport.Skip();
                                        end;
                                        OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                          "Sales Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateShptHeader;
                                            OnSalesLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Sales Header");
                                        end;
                                        if not WhseActivityCreate.FromSalesLine2ShptLine(WhseShptHeader, "Sales Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                            end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if OneHeaderCreated or WhseHeaderCreated then begin
                            UpdateReceiptHeaderStatus;
                            CheckFillQtyToHandle;
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        if (("Warehouse Request".Type = "Warehouse Request".Type::Outbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Sales Order")) or
                           (("Warehouse Request".Type = "Warehouse Request".Type::Inbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Sales Return Order"))
                        then
                            SetFilter("Outstanding Quantity", '>0')
                        else
                            SetFilter("Outstanding Quantity", '<0');
                        SetRange("Drop Shipment", false);
                        SetRange("Job No.", '');

                        OnAfterSalesLineOnPreDataItem("Sales Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    SkipRecord: Boolean;
                    BreakReport: Boolean;
                begin
                    TestField("Sell-to Customer No.");
                    Cust.Get("Sell-to Customer No.");
                    if not SkipBlockedCustomer then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                    SalesHeaderCounted := false;

                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterSalesHeaderOnAfterGetRecord("Sales Header", SkipRecord, BreakReport, "Warehouse Request");
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> DATABASE::"Sales Line" then
                        CurrReport.Break();

                    OnAfterSalesHeaderOnPreDataItem("Sales Header");
                end;
            }
            dataitem("Purchase Header"; "Purchase Header")
            {
                DataItemLink = "Document Type" = FIELD("Source Subtype"), "No." = FIELD("Source No.");
                DataItemTableView = SORTING("Document Type", "No.");
                dataitem("Purchase Line"; "Purchase Line")
                {
                    DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforePurchaseLineOnAfterGetRecord("Purchase Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        VerifyItemNotBlocked("No.");
                        if "Location Code" = "Warehouse Request"."Location Code" then
                            case RequestType of
                                RequestType::Receive:
                                    if WhseActivityCreate.CheckIfPurchLine2ReceiptLine("Purchase Line") then begin
                                        OnPurchaseLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                          "Purchase Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateReceiptHeader;
                                            OnPurchaseLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Purchase Header");
                                        end;
                                        if not WhseActivityCreate.PurchLine2ReceiptLine(WhseReceiptHeader, "Purchase Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                                RequestType::Ship:
                                    if WhseActivityCreate.CheckIfFromPurchLine2ShptLine("Purchase Line") then begin
                                        OnPurchaseLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                          "Purchase Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateShptHeader;
                                            OnPurchaseLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Purchase Header");
                                        end;
                                        if not WhseActivityCreate.FromPurchLine2ShptLine(WhseShptHeader, "Purchase Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                            end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if OneHeaderCreated or WhseHeaderCreated then begin
                            UpdateReceiptHeaderStatus;
                            CheckFillQtyToHandle;
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        if (("Warehouse Request".Type = "Warehouse Request".Type::Inbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Purchase Order")) or
                           (("Warehouse Request".Type = "Warehouse Request".Type::Outbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Purchase Return Order"))
                        then
                            SetFilter("Outstanding Quantity", '>0')
                        else
                            SetFilter("Outstanding Quantity", '<0');
                        SetRange("Drop Shipment", false);
                        SetRange("Job No.", '');

                        OnAfterPurchaseLineOnPreDataItem("Purchase Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BreakReport: Boolean;
                    SkipRecord: Boolean;
                begin
                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterPurchaseHeaderOnAfterGetRecord("Purchase Header", SkipRecord, BreakReport, "Warehouse Request");
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> DATABASE::"Purchase Line" then
                        CurrReport.Break();

                    OnAfterOnPreDataItemPurchaseLine("Purchase Header");
                end;
            }
            dataitem("Transfer Header"; "Transfer Header")
            {
                DataItemLink = "No." = FIELD("Source No.");
                DataItemTableView = SORTING("No.");
                dataitem("Transfer Line"; "Transfer Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeTransferLineOnAfterGetRecord("Transfer Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        case RequestType of
                            RequestType::Receive:
                                if WhseActivityCreate.CheckIfTransLine2ReceiptLine("Transfer Line") then begin
                                    OnTransferLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                      "Transfer Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                    if not OneHeaderCreated and not WhseHeaderCreated then begin
                                        CreateReceiptHeader;
                                        OnTransferLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Transfer Header");
                                    end;
                                    if not WhseActivityCreate.TransLine2ReceiptLine(WhseReceiptHeader, "Transfer Line") then
                                        ErrorOccured := true;
                                    LineCreated := true;
                                end;
                            RequestType::Ship:
                                if WhseActivityCreate.CheckIfFromTransLine2ShptLine("Transfer Line") then begin
                                    OnTransferLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                      "Transfer Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated);
                                    if not OneHeaderCreated and not WhseHeaderCreated then begin
                                        CreateShptHeader;
                                        OnTransferLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Transfer Header");
                                    end;
                                    if not WhseActivityCreate.FromTransLine2ShptLine(WhseShptHeader, "Transfer Line") then
                                        ErrorOccured := true;
                                    LineCreated := true;
                                end;
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if OneHeaderCreated or WhseHeaderCreated then begin
                            UpdateReceiptHeaderStatus;
                            CheckFillQtyToHandle;
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        case "Warehouse Request"."Source Subtype" of
                            0:
                                SetFilter("Outstanding Quantity", '>0');
                            1:
                                SetFilter("Qty. in Transit", '>0');
                        end;

                        OnAfterTransferLineOnPreDataItem("Transfer Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BreakReport: Boolean;
                    SkipRecord: Boolean;
                begin
                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterTransHeaderOnAfterGetRecord("Transfer Header", SkipRecord, BreakReport, "Warehouse Request");
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> DATABASE::"Transfer Line" then
                        CurrReport.Break();

                    OnAfterOnPreDataItemTransferLine("Transfer Header");
                end;
            }
            dataitem("Service Header"; "Service Header")
            {
                DataItemLink = "Document Type" = FIELD("Source Subtype"), "No." = FIELD("Source No.");
                DataItemTableView = SORTING("Document Type", "No.");
                dataitem("Service Line"; "Service Line")
                {
                    DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeServiceLineOnAfterGetRecord("Service Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if "Location Code" = "Warehouse Request"."Location Code" then
                            case RequestType of
                                RequestType::Ship:
                                    if WhseActivityCreate.CheckIfFromServiceLine2ShptLin("Service Line") then begin
                                        if not OneHeaderCreated and not WhseHeaderCreated then
                                            CreateShptHeader;
                                        if not WhseActivityCreate.FromServiceLine2ShptLine(WhseShptHeader, "Service Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                            end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        if (("Warehouse Request".Type = "Warehouse Request".Type::Outbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Service Order"))
                        then
                            SetFilter("Outstanding Quantity", '>0')
                        else
                            SetFilter("Outstanding Quantity", '<0');
                        SetRange("Job No.", '');

                        OnAfterServiceLineOnPreDataItem("Service Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TestField("Bill-to Customer No.");
                    Cust.Get("Bill-to Customer No.");
                    if not SkipBlockedCustomer then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false)
                    else
                        if Cust.Blocked <> Cust.Blocked::" " then
                            CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> DATABASE::"Service Line" then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            var
                WhseSetup: Record "Warehouse Setup";
                SkipRecord: Boolean;
                BreakReport: Boolean;
            begin
                WhseHeaderCreated := false;
                OnBeforeWarehouseRequestOnAfterGetRecord(
                  "Warehouse Request", WhseHeaderCreated, SkipRecord, BreakReport, RequestType, WhseReceiptHeader, WhseShptHeader, OneHeaderCreated);
                if BreakReport then
                    CurrReport.Break();
                if SkipRecord then
                    CurrReport.Skip();

                case Type of
                    Type::Inbound:
                        begin
                            if not Location.RequireReceive("Location Code") then begin
                                if "Location Code" = '' then
                                    WhseSetup.TestField("Require Receive");
                                Location.Get("Location Code");
                                Location.TestField("Require Receive");
                            end;
                            if not OneHeaderCreated then
                                RequestType := RequestType::Receive;
                        end;
                    Type::Outbound:
                        begin
                            if not Location.RequireShipment("Location Code") then begin
                                if "Location Code" = '' then
                                    WhseSetup.TestField("Require Shipment");
                                Location.Get("Location Code");
                                Location.TestField("Require Shipment");
                            end;
                            if not OneHeaderCreated then
                                RequestType := RequestType::Ship;
                        end;
                end;
            end;

            trigger OnPostDataItem()
            var
                IsHandled: Boolean;
            begin
                IsHandled := not (WhseHeaderCreated or OneHeaderCreated);
                OnBeforeCreateWhseDocuments(WhseReceiptHeader, WhseShptHeader, IsHandled, "Warehouse Request");
                if not IsHandled then begin
                    OnAfterCreateWhseDocuments(WhseReceiptHeader, WhseShptHeader, WhseHeaderCreated, "Warehouse Request");
                    WhseShptHeader.SortWhseDoc;
                    WhseReceiptHeader.SortWhseDoc;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if OneHeaderCreated then begin
                    case RequestType of
                        RequestType::Receive:
                            Type := Type::Inbound;
                        RequestType::Ship:
                            Type := Type::Outbound;
                    end;
                    SetRange(Type, Type);
                end;

                OnAfterWarehouseRequestOnPreDataItem("Warehouse Request");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandle)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if the Quantity to Handle field in the warehouse document is prefilled according to the source document quantities.';
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

    trigger OnPostReport()
    begin
        if not HideDialog then
            case RequestType of
                RequestType::Receive:
                    ShowReceiptDialog;
                RequestType::Ship:
                    ShowShipmentDialog;
            end;
        if SkippedSourceDoc > 0 then
            Message(CustomerIsBlockedMsg, SkippedSourceDoc);
        Completed := true;
    end;

    trigger OnPreReport()
    begin
        ActivitiesCreated := 0;
        LineCreated := false;
    end;

    var
        Text000: Label 'There are no Warehouse Receipt Lines created.';
        Text001: Label '%1 %2 has been created.';
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        Cust: Record Customer;
        WhseActivityCreate: Codeunit "Whse.-Create Source Document";
        ActivitiesCreated: Integer;
        OneHeaderCreated: Boolean;
        Completed: Boolean;
        LineCreated: Boolean;
        WhseHeaderCreated: Boolean;
        DoNotFillQtytoHandle: Boolean;
        HideDialog: Boolean;
        SkipBlockedCustomer: Boolean;
        SkipBlockedItem: Boolean;
        RequestType: Option Receive,Ship;
        SalesHeaderCounted: Boolean;
        SkippedSourceDoc: Integer;
        Text002: Label '%1 Warehouse Receipts have been created.';
        Text003: Label 'There are no Warehouse Shipment Lines created.';
        Text004: Label '%1 Warehouse Shipments have been created.';
        ErrorOccured: Boolean;
        Text005: Label 'One or more of the lines on this %1 require special warehouse handling. The %2 for such lines has been set to blank.';
        CustomerIsBlockedMsg: Label '%1 source documents were not included because the customer is blocked.';
        SuppressCommit: Boolean;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetOneCreatedShptHeader(WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader := WhseShptHeader2;
        if WhseShptHeader.Find then
            OneHeaderCreated := true;
    end;

    procedure SetOneCreatedReceiptHeader(WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader := WhseReceiptHeader2;
        if WhseReceiptHeader.Find then
            OneHeaderCreated := true;
    end;

    procedure SetDoNotFillQtytoHandle(DoNotFillQtytoHandle2: Boolean)
    begin
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
    end;

    procedure GetLastShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader2 := WhseShptHeader;
    end;

    procedure GetLastReceiptHeader(var WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader2 := WhseReceiptHeader;
    end;

    procedure NotCancelled(): Boolean
    begin
        exit(Completed);
    end;

    local procedure CreateShptHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateShptHeader(WhseShptHeader, "Warehouse Request", "Sales Line", IsHandled);
        if IsHandled then
            exit;

        WhseShptHeader.Init();
        WhseShptHeader."No." := '';
        WhseShptHeader."Location Code" := "Warehouse Request"."Location Code";
        if Location.Code = WhseShptHeader."Location Code" then
            WhseShptHeader."Bin Code" := Location."Shipment Bin Code";
        WhseShptHeader."External Document No." := "Warehouse Request"."External Document No.";
        WhseShptLine.LockTable();
        OnBeforeWhseShptHeaderInsert(WhseShptHeader, "Warehouse Request");
        WhseShptHeader.Insert(true);
        ActivitiesCreated := ActivitiesCreated + 1;
        WhseHeaderCreated := true;

        OnAfterCreateShptHeader(WhseShptHeader, "Warehouse Request", "Sales Line");
    end;

    procedure CreateReceiptHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateRcptHeader(WhseReceiptHeader, "Warehouse Request", "Purchase Line", IsHandled);
        if IsHandled then
            exit;

        WhseReceiptHeader.Init();
        WhseReceiptHeader."No." := '';
        WhseReceiptHeader."Location Code" := "Warehouse Request"."Location Code";
        if Location.Code = WhseReceiptHeader."Location Code" then
            WhseReceiptHeader."Bin Code" := Location."Receipt Bin Code";
        WhseReceiptHeader."Vendor Shipment No." := "Warehouse Request"."External Document No.";
        WhseReceiptLine.LockTable();
        OnBeforeWhseReceiptHeaderInsert(WhseReceiptHeader, "Warehouse Request");
        WhseReceiptHeader.Insert(true);
        ActivitiesCreated := ActivitiesCreated + 1;
        WhseHeaderCreated := true;
        if not SuppressCommit then
            Commit();

        OnAfterCreateRcptHeader(WhseReceiptHeader, "Warehouse Request", "Purchase Line");
    end;

    local procedure UpdateReceiptHeaderStatus()
    begin
        with WhseReceiptHeader do begin
            if "No." = '' then
                exit;
            Validate("Document Status", GetHeaderStatus(0));
            Modify(true);
        end;
    end;

    procedure SetSkipBlocked(Skip: Boolean)
    begin
        SkipBlockedCustomer := Skip;
    end;

    procedure SetSkipBlockedItem(Skip: Boolean)
    begin
        SkipBlockedItem := Skip;
    end;

    local procedure VerifyItemNotBlocked(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if SkipBlockedItem and Item.Blocked then
            CurrReport.Skip();

        Item.TestField(Blocked, false);
    end;

    procedure ShowReceiptDialog()
    var
        SpecialHandlingMessage: Text[1024];
    begin
        if not LineCreated then
            Error(Text000);

        if ErrorOccured then
            SpecialHandlingMessage :=
              ' ' + StrSubstNo(Text005, WhseReceiptHeader.TableCaption, WhseReceiptLine.FieldCaption("Bin Code"));
        if (ActivitiesCreated = 0) and LineCreated and ErrorOccured then
            Message(SpecialHandlingMessage);
        if ActivitiesCreated = 1 then
            Message(StrSubstNo(Text001, ActivitiesCreated, WhseReceiptHeader.TableCaption) + SpecialHandlingMessage);
        if ActivitiesCreated > 1 then
            Message(StrSubstNo(Text002, ActivitiesCreated) + SpecialHandlingMessage);
    end;

    procedure ShowShipmentDialog()
    var
        SpecialHandlingMessage: Text[1024];
    begin
        if not LineCreated then
            Error(Text003);

        if ErrorOccured then
            SpecialHandlingMessage :=
              ' ' + StrSubstNo(Text005, WhseShptHeader.TableCaption, WhseShptLine.FieldCaption("Bin Code"));
        if (ActivitiesCreated = 0) and LineCreated and ErrorOccured then
            Message(SpecialHandlingMessage);
        if ActivitiesCreated = 1 then
            Message(StrSubstNo(Text001, ActivitiesCreated, WhseShptHeader.TableCaption) + SpecialHandlingMessage);
        if ActivitiesCreated > 1 then
            Message(StrSubstNo(Text004, ActivitiesCreated) + SpecialHandlingMessage);
    end;

    local procedure CheckFillQtyToHandle()
    begin
        OnBeforeCheckFillQtyToHandle(DoNotFillQtytoHandle, RequestType);

        if DoNotFillQtytoHandle and (RequestType = RequestType::Receive) then begin
            WhseReceiptLine.Reset();
            WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
            WhseReceiptLine.DeleteQtyToReceive(WhseReceiptLine);
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseRequest: Record "Warehouse Request"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocuments(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseShipmentHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemPurchaseLine(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemTransferLine(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDocumentLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderOnAfterGetRecord(SalesHeader: Record "Sales Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransHeaderOnAfterGetRecord(TransferHeader: Record "Transfer Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseHeaderOnAfterGetRecord(PurchaseHeader: Record "Purchase Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderOnPreDataItem(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineOnPreDataItem(var SalesLine: Record "Sales Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineOnPreDataItem(var ServiceLine: Record "Service Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineOnPreDataItem(var PurchaseLine: Record "Purchase Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferLineOnPreDataItem(var TransferLine: Record "Transfer Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWarehouseRequestOnPreDataItem(var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFillQtyToHandle(var DoNotFillQtytoHandle: Boolean; var RequestType: Option);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseLineOnAfterGetRecord(PurchaseLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineOnAfterGetRecord(SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineOnAfterGetRecord(ServiceLine: Record "Service Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineOnAfterGetRecord(TransferLine: Record "Transfer Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseRequestOnAfterGetRecord(var WarehouseRequest: Record "Warehouse Request"; var WhseHeaderCreated: Boolean; var SkipRecord: Boolean; var BreakReport: Boolean; RequestType: Option Receive,Ship; var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseReceiptHeaderInsert(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptHeaderInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; PurchaseHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; PurchaseHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCreateRcptHeader(SalesLine: Record "Sales Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader(SalesLine: Record "Sales Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterGetRecordOnBeforeCreateRcptHeader(PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterGetRecordOnBeforeCreateShptHeader(PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; TransferHeader: Record "Transfer Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; TransferHeader: Record "Transfer Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterGetRecordOnBeforeCreateRcptHeader(TransferLine: Record "Transfer Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterGetRecordOnBeforeCreateShptHeader(TransferLine: Record "Transfer Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;
}

