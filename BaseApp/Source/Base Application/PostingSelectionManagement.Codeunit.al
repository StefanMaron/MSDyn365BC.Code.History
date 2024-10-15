codeunit 99 "Posting Selection Management"
{
    trigger OnRun()
    begin

    end;

    var
        ShipInvoiceOptionsQst: Label '&Ship,&Invoice,Ship &and Invoice';
        ReceiveInvoiceOptionsQst: Label '&Receive,&Invoice,Receive &and Invoice';
        ShipInvoiceFromWhseQst: Label '&Ship,Ship &and Invoice';
        ReceiveInvoiceFromWhseQst: Label '&Receive,Receive &and Invoice';
        PostDocConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        PostWhseAndDocConfirmQst: Label 'Do you want to post the %1 and %2?', Comment = '%1 = Activity Type, %2 = Document Type';
        PostAndPrintConfirmQst: Label 'Do you want to post and print the %1?', Comment = '%1 = Document Type';
        PostAndEmailConfirmQst: Label 'Do you want to post and email the %1?', Comment = '%1 = Document Type';
        ShipConfirmQst: Label 'Do you want to post the shipment?';
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
        ReceiveConfirmQst: Label 'Do you want to post the receipt?';
        ReceiveInvoiceConfirmQst: Label 'Do you want to post the receipt and invoice?';
        PostingInvoiceProhibitedErr: Label 'You cannot post the invoice because %1 is %2 in %3.', Comment = '%1 = Invoice Posting Policy, %2 = Prohibited, %3 = User Setup';

    procedure ConfirmPostSalesDocument(var SalesHeaderToPost: Record "Sales Header"; DefaultOption: Integer; WithPrint: Boolean; WithEmail: Boolean) Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
    begin
        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        SalesHeader.Copy(SalesHeaderToPost);

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    OnConfirmPostSalesDocumentOnBeforeSalesOrderGetSalesInvoicePostingPolicy(SalesHeader);
                    UserSetupManagement.GetSalesInvoicePostingPolicy(SalesHeader.Ship, SalesHeader.Invoice);
                    case true of
                        not SalesHeader.Ship and not SalesHeader.Invoice:
                            begin
                                Selection := StrMenu(ShipInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                SalesHeader.Ship := Selection in [1, 3];
                                SalesHeader.Invoice := Selection in [2, 3];
                            end;
                        SalesHeader.Ship and not SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                                exit(false);
                        SalesHeader.Ship and SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    OnConfirmPostSalesDocumentOnBeforeSalesOrderReturnGetSalesInvoicePostingPolicy(SalesHeader);
                    UserSetupManagement.GetSalesInvoicePostingPolicy(SalesHeader.Receive, SalesHeader.Invoice);
                    case true of
                        not SalesHeader.Receive and not SalesHeader.Invoice:
                            begin
                                Selection := StrMenu(ReceiveInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                SalesHeader.Receive := Selection in [1, 3];
                                SalesHeader.Invoice := Selection in [2, 3];
                            end;
                        SalesHeader.Receive and not SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                                exit(false);
                        SalesHeader.Receive and SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo":
                begin
                    CheckUserCanInvoiceSales();
                    if not ConfirmManagement.GetResponseOrDefault(
                            GetPostConfirmationMessage(LowerCase(Format(SalesHeader."Document Type")), WithPrint, WithEmail), true)
                    then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                        GetPostConfirmationMessage(LowerCase(Format(SalesHeader."Document Type")), WithPrint, WithEmail), true)
                then
                    exit(false);
        end;

        SalesHeaderToPost.Copy(SalesHeader);
        exit(true);
    end;

    procedure ConfirmPostPurchaseDocument(var PurchaseHeaderToPost: Record "Purchase Header"; DefaultOption: Integer; WithPrint: Boolean; WithEmail: Boolean) Result: Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
    begin
        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        PurchaseHeader.Copy(PurchaseHeaderToPost);

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    UserSetupManagement.GetPurchaseInvoicePostingPolicy(PurchaseHeader.Receive, PurchaseHeader.Invoice);
                    case true of
                        not PurchaseHeader.Receive and not PurchaseHeader.Invoice:
                            begin
                                Selection := StrMenu(ReceiveInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                PurchaseHeader.Receive := Selection in [1, 3];
                                PurchaseHeader.Invoice := Selection in [2, 3];
                            end;
                        PurchaseHeader.Receive and not PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                                exit(false);
                        PurchaseHeader.Receive and PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            PurchaseHeader."Document Type"::"Return Order":
                begin
                    UserSetupManagement.GetPurchaseInvoicePostingPolicy(PurchaseHeader.Ship, PurchaseHeader.Invoice);
                    case true of
                        not PurchaseHeader.Ship and not PurchaseHeader.Invoice:
                            begin
                                Selection := StrMenu(ShipInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                PurchaseHeader.Ship := Selection in [1, 3];
                                PurchaseHeader.Invoice := Selection in [2, 3];
                            end;
                        PurchaseHeader.Ship and not PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                                exit(false);
                        PurchaseHeader.Ship and PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    CheckUserCanInvoicePurchase();
                    if not ConfirmManagement.GetResponseOrDefault(
                            GetPostConfirmationMessage(LowerCase(Format(PurchaseHeader."Document Type")), WithPrint, WithEmail), true)
                    then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                        GetPostConfirmationMessage(LowerCase(Format(PurchaseHeader."Document Type")), WithPrint, WithEmail), true)
                then
                    exit(false);
        end;

        PurchaseHeaderToPost.Copy(PurchaseHeader);
        exit(true);
    end;

    procedure ConfirmPostWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Selection: Integer; DefaultOption: Integer; WithPrint: Boolean) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if DefaultOption < 1 then
            DefaultOption := 1;
        if DefaultOption > 2 then
            DefaultOption := 2;

        case WarehouseActivityLine."Activity Type" of
            WarehouseActivityLine."Activity Type"::"Invt. Put-away":
                begin
                    if WarehouseActivityLine."Source Document" in ["Warehouse Activity Source Document"::"Prod. Output",
                                                               "Warehouse Activity Source Document"::"Inbound Transfer",
                                                               "Warehouse Activity Source Document"::"Prod. Consumption"]
                    then
                        exit(
                            ConfirmManagement.GetResponseOrDefault(
                              StrSubstNo(PostWhseAndDocConfirmQst, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Source Document"), false));

                    exit(GetReceiveInvoiceSelectionForWhseActivity(DefaultOption, Selection));
                end;
            else begin
                if WarehouseActivityLine."Source Document" in ["Warehouse Activity Source Document"::"Prod. Consumption",
                                                            "Warehouse Activity Source Document"::"Outbound Transfer",
                                                            "Warehouse Activity Source Document"::"Job Usage"]
                then
                    exit(
                    ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(PostWhseAndDocConfirmQst, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Source Document"), false));

                exit(GetShipInvoiceSelectionForWhseActivity(DefaultOption, Selection));
            end;
        end;

        exit(true);
    end;

    procedure ConfirmPostWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Selection: Integer) Result: Boolean
    var
        DefaultOption: Integer;
    begin
        DefaultOption := 1;
        Result := GetShipInvoiceSelectionForWhseActivity(DefaultOption, Selection);
        exit(Result);
    end;

    internal procedure CheckUserCanInvoiceSales()
    var
        UserSetup: Record "User Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        Ship: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetSalesInvoicePostingPolicy(Ship, Invoice);
        if Ship and not Invoice then
            Error(
              PostingInvoiceProhibitedErr,
              UserSetup.FieldCaption("Sales Invoice Posting Policy"), Format("Invoice Posting Policy"::Prohibited),
              UserSetup.TableCaption);
    end;

    internal procedure CheckUserCanInvoicePurchase()
    var
        UserSetup: Record "User Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        Receive: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
        if Receive and not Invoice then
            Error(
              PostingInvoiceProhibitedErr,
              UserSetup.FieldCaption("Purch. Invoice Posting Policy"), Format("Invoice Posting Policy"::Prohibited),
              UserSetup.TableCaption);
    end;

    local procedure GetShipInvoiceSelectionForWhseActivity(DefaultOption: Integer; var Selection: Integer): Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Ship: Boolean;
        Invoice, IsHandled, Result : Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeGetShipInvoiceSelectionForWhseActivity(DefaultOption, Selection, IsHandled, Result);
        if IsHandled then
            exit(Result);

        UserSetupManagement.GetSalesInvoicePostingPolicy(Ship, Invoice);
        case true of
            not Ship and not Invoice:
                begin
                    Selection := StrMenu(ShipInvoiceFromWhseQst, DefaultOption);
                    if Selection = 0 then
                        exit(false);
                end;
            Ship and not Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                        exit(false);
                    Selection := 1;
                end;
            Ship and Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                        exit(false);
                    Selection := 2;
                end;
        end;
        exit(true);
    end;

    local procedure GetReceiveInvoiceSelectionForWhseActivity(DefaultOption: Integer; var Selection: Integer): Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Receive: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
        case true of
            not Receive and not Invoice:
                begin
                    Selection := StrMenu(ReceiveInvoiceFromWhseQst, DefaultOption);
                    if Selection = 0 then
                        exit(false);
                end;
            Receive and not Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                        exit(false);
                    Selection := 1;
                end;
            Receive and Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                        exit(false);
                    Selection := 2;
                end;
        end;
        exit(true);
    end;

    local procedure GetPostConfirmationMessage(What: Text; WithPrint: Boolean; WithEmail: Boolean): Text
    begin
        if WithPrint then
            exit(StrSubstNo(PostAndPrintConfirmQst, What));

        if WithEmail then
            exit(StrSubstNo(PostAndEmailConfirmQst, What));

        exit(StrSubstNo(PostDocConfirmQst, What));
    end;

    local procedure GetShipConfirmationMessage(): Text
    begin
        exit(ShipConfirmQst);
    end;

    local procedure GetShipInvoiceConfirmationMessage(): Text
    begin
        exit(ShipInvoiceConfirmQst);
    end;

    local procedure GetReceiveConfirmationMessage(): Text
    begin
        exit(ReceiveConfirmQst);
    end;

    local procedure GetReceiveInvoiceConfirmationMessage(): Text
    begin
        exit(ReceiveInvoiceConfirmQst);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostSalesDocumentOnBeforeSalesOrderGetSalesInvoicePostingPolicy(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostSalesDocumentOnBeforeSalesOrderReturnGetSalesInvoicePostingPolicy(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShipInvoiceSelectionForWhseActivity(DefaultOption: Integer; var Selection: Integer; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}
