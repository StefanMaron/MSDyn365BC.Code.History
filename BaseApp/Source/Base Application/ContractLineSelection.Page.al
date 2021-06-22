page 6057 "Contract Line Selection"
{
    Caption = 'Contract Line Selection';
    DataCaptionFields = "Customer No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Service Item";

    layout
    {
        area(content)
        {
            field(SelectionFilter; SelectionFilter)
            {
                ApplicationArea = Service;
                Caption = 'Selection Filter';
                OptionCaption = 'All Service Items,Service Items without Contract';
                ToolTip = 'Specifies a selection filter.';

                trigger OnValidate()
                begin
                    SelectionFilterOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number linked to the service item.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this item.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns this item.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the vendor for this item.';
                    Visible = false;
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                    Visible = false;
                }
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
        area(navigation)
        {
            group("&Serv. Item")
            {
                Caption = '&Serv. Item';
                Image = ServiceItem;
                action("&Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Service Item Card";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageOnRec = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the service contract.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        OKButton := false;
        SetCurrentKey("Customer No.", "Ship-to Code");
        FilterGroup(2);
        SetRange("Customer No.", CustomerNo);
        SetFilter(Status, '<>%1', Status::Defective);
        FilterGroup(0);
        SetRange("Ship-to Code", ShipToCode);
        SetSelectionFilter;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
        if OKButton then begin
            ServContract.Get(ContractType, ContractNo);
            CurrPage.SetSelectionFilter(Rec);
            ServContractLine.HideDialogBox(true);
            if Find('-') then
                repeat
                    CheckServContractLine;
                until Next = 0;
            CreateServContractLines;
            Commit();
        end;
    end;

    var
        ServContract: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        TempServItem: Record "Service Item" temporary;
        OKButton: Boolean;
        CustomerNo: Code[20];
        ShipToCode: Code[10];
        ContractNo: Code[20];
        ContractType: Integer;
        LineNo: Integer;
        Text000: Label '%1 %2 already exists in this service contract.', Comment = 'Service Item 1 already exists in this service contract.';
        Text001: Label '%1 %2 already belongs to one or more service contracts/quotes.\\Do you want to include this service item into the document?', Comment = 'Service Item 1 already belongs to one or more service contracts/quotes.\\Do you want to include this service item into the document?';
        Text002: Label '%1 %2 has a different ship-to code for this customer.\\Do you want to include this service item into the document?', Comment = 'Service Item 1 has a different ship-to code for this customer.\\Do you want to include this service item into the document?';
        SelectionFilter: Option "All Service Items","Service Items without Contract";

    procedure SetSelection(CustNo: Code[20]; ShipNo: Code[10]; CtrType: Integer; CtrNo: Code[20])
    begin
        CustomerNo := CustNo;
        ShipToCode := ShipNo;
        ContractType := CtrType;
        ContractNo := CtrNo;
    end;

    local procedure FindlineNo(): Integer
    begin
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ContractType);
        ServContractLine.SetRange("Contract No.", ContractNo);
        if ServContractLine.FindLast then
            exit(ServContractLine."Line No.");

        exit(0);
    end;

    local procedure CheckServContractLine()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        TempServItem := Rec;

        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Service Item No.");
        ServContractLine.SetRange("Contract No.", ServContract."Contract No.");
        ServContractLine.SetRange("Contract Type", ServContract."Contract Type");
        ServContractLine.SetRange("Service Item No.", TempServItem."No.");
        if ServContractLine.FindFirst then begin
            Message(Text000, TempServItem.TableCaption, TempServItem."No.");
            exit;
        end;

        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
        ServContractLine.SetRange("Service Item No.", TempServItem."No.");
        ServContractLine.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
        ServContractLine.SetFilter("Contract No.", '<>%1', ServContract."Contract No.");
        if ServContractLine.FindFirst then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, TempServItem.TableCaption, TempServItem."No."), true)
            then
                exit;
        end else begin
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Service Item No.");
            ServContractLine.SetRange("Service Item No.", TempServItem."No.");
            ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Quote);
            ServContractLine.SetFilter("Contract No.", '<>%1', ServContract."Contract No.");
            if ServContractLine.FindFirst then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(Text001, TempServItem.TableCaption, TempServItem."No."), true)
                then
                    exit;
        end;

        if TempServItem."Ship-to Code" <> ServContract."Ship-to Code" then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text002, TempServItem.TableCaption, TempServItem."No."), true)
            then
                exit;

        TempServItem.Insert();
    end;

    local procedure CreateServContractLines()
    begin
        ServContractLine.LockTable();
        LineNo := FindlineNo + 10000;
        if TempServItem.Find('-') then
            repeat
                ServContractLine.Init();
                ServContractLine.HideDialogBox(true);
                ServContractLine."Contract Type" := ServContract."Contract Type";
                ServContractLine."Contract No." := ServContract."Contract No.";
                ServContractLine."Line No." := LineNo;
                ServContractLine.SetupNewLine;
                ServContractLine.Validate("Service Item No.", TempServItem."No.");
                ServContractLine.Validate("Line Value", TempServItem."Default Contract Value");
                ServContractLine.Validate("Line Discount %", TempServItem."Default Contract Discount %");
                ServContractLine.Insert(true);
                LineNo := LineNo + 10000;
            until TempServItem.Next = 0
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Service Items":
                SetRange("No. of Active Contracts");
            SelectionFilter::"Service Items without Contract":
                SetRange("No. of Active Contracts", 0);
        end;
        CurrPage.Update(false);
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update;
        SetSelectionFilter;
    end;

    local procedure LookupOKOnPush()
    begin
        OKButton := "No." <> '';
    end;
}

