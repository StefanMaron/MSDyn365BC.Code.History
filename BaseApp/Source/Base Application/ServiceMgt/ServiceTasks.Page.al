page 5915 "Service Tasks"
{
    ApplicationArea = Service;
    Caption = 'Service Tasks';
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Service Item Line";
    SourceTableView = SORTING("Response Date", "Response Time", Priority);
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ResourceFilter; ResourceFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines that a certain resource is allocated to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Res.Reset();
                        if PAGE.RunModal(0, Res) = ACTION::LookupOK then begin
                            Text := Res."No.";
                            SetResourceFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FilterGroup(2);
                        TempTextFilter := GetFilter("Resource Filter");
                        FilterGroup(0);
                        SetResourceFilter();
                        if not TestFilter() then begin
                            ResourceFilter := TempTextFilter;
                            SetResourceFilter();
                            Error(Text000, TableCaption);
                        end;
                        ResourceFilterOnAfterValidate();
                    end;
                }
                field(ResourceGroupFilter; ResourceGroupFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Group Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines with the specified resource group allocated to each of them.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ResourceGroup.Reset();
                        if PAGE.RunModal(0, ResourceGroup) = ACTION::LookupOK then begin
                            Text := ResourceGroup."No.";
                            SetResourceGroupFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FilterGroup(2);
                        TempTextFilter := GetFilter("Resource Group Filter");
                        FilterGroup(0);
                        SetResourceGroupFilter();
                        if not TestFilter() then begin
                            ResourceGroupFilter := TempTextFilter;
                            SetResourceGroupFilter();
                            Error(Text000, TableCaption);
                        end;
                        ResourceGroupFilterOnAfterVali();
                    end;
                }
                field(RespDateFilter; RespDateFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Response Date Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines with the specified value in the Response Date field.';

                    trigger OnValidate()
                    begin
                        FilterGroup(2);
                        TempTextFilter := GetFilter("Response Date");
                        FilterGroup(0);
                        SetRespDateFilter();
                        if not TestFilter() then begin
                            RespDateFilter := TempTextFilter;
                            SetRespDateFilter();
                            Error(Text000, TableCaption);
                        end;
                        RespDateFilterOnAfterValidate();
                    end;
                }
                field(AllocationStatus; AllocationStatus)
                {
                    ApplicationArea = Service;
                    Caption = 'Allocation Status Filter';
                    OptionCaption = ' ,Nonactive,Active,Finished,Canceled,Reallocation Needed';
                    ToolTip = 'Specifies the filter that displays the service tasks corresponding to service item lines with a certain value in the Status Code of Resource Allocations.';

                    trigger OnValidate()
                    begin
                        TempAllocationStatus := "Allocation Status Filter";
                        SetAllocationFilter();
                        if not TestFilter() then begin
                            AllocationStatus := TempAllocationStatus;
                            SetAllocationFilter();
                            Error(Text000, TableCaption);
                        end;
                        AllocationStatusOnAfterValidat();
                    end;
                }
                field(DocFilter; DocFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Document Filter';
                    OptionCaption = 'Order,Quote,All';
                    ToolTip = 'Specifies the filter that displays all service tasks corresponding to documents of the specified type.';

                    trigger OnValidate()
                    begin
                        ServOrderFilter := '';
                        SetServOrderFilter();
                        SetDocFilter();
                        DocFilterOnAfterValidate();
                    end;
                }
                field(ServOrderFilter; ServOrderFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'No. Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to the service item lines within the specified document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServHeader.Reset();
                        SetDocFilterHeader(ServHeader);
                        if PAGE.RunModal(0, ServHeader) = ACTION::LookupOK then begin
                            Text := ServHeader."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FilterGroup(2);
                        TempTextFilter := GetFilter("Document No.");
                        FilterGroup(0);
                        SetServOrderFilter();
                        if not TestFilter() then begin
                            ServOrderFilter := TempTextFilter;
                            SetServOrderFilter();
                            Error(Text000, TableCaption());
                        end;
                        ServOrderFilterOnAfterValidate();
                    end;
                }
                field(RepairStatusFilter; RepairStatusFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Repair Status Code Filter';
                    ToolTip = 'Specifies the Repair Status Code filter to view service tasks corresponding to service item lines with the specified repair status code.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        RepairStatus.Reset();
                        if PAGE.RunModal(0, RepairStatus) = ACTION::LookupOK then begin
                            Text := RepairStatus.Code;
                            SetRepStatFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FilterGroup(2);
                        TempTextFilter := GetFilter("Repair Status Code");
                        FilterGroup(0);
                        SetRepStatFilter();
                        if not TestFilter() then begin
                            RepairStatusFilter := TempTextFilter;
                            SetRepStatFilter();
                            Error(Text000, TableCaption);
                        end;
                        RepairStatusFilterOnAfterValid();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when service should start on this service item line.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when service should start on this service item.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service priority for this item.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the service document is a service order or service quote.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order linked to this service item line.';
                }
                field("Repair Status Code"; Rec."Repair Status Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the repair status of this service item.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number registered in the Service Item table.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer number associated with the service contract.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Cust.Name"; Cust.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer.';
                    Visible = false;
                }
                field("Service Shelf No."; Rec."Service Shelf No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service shelf this item is stored on.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to this service item.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group for this item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ItemLedgerEntry);
                        ItemLedgerEntry.SetRange("Item No.", "Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", "Variant Code");
                        ItemLedgerEntry.SetRange("Serial No.", "Serial No.");
                        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this service item.';
                    Visible = false;
                }
                field(Warranty; Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that warranty on either parts or labor exists for this item.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract associated with the item or service on the line.';
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of resource allocations with the allocation status specified in the Allocation Status Filter field.';
                }
            }
            group(Control44)
            {
                ShowCaption = false;
                field(Description2; Description)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a description of this service item.';
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
            group("&Service Tasks")
            {
                Caption = '&Service Tasks';
                Image = ServiceTasks;
                action("&Show Document")
                {
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        if ServHeader.Get("Document Type", "Document No.") then begin
                            PageManagement.PageRunModal(ServHeader);

                            if ServOrderFilter <> '' then begin
                                ServItemLine.Reset();
                                ServItemLine.CopyFilters(Rec);
                                if ServItemLine.GetRangeMin("Document No.") = ServItemLine.GetRangeMax("Document No.") then
                                    if ServItemLine.IsEmpty() then begin
                                        ServOrderFilter := '';
                                        SetServOrderFilter();
                                    end
                            end;
                        end;
                    end;
                }
                action("&Item Worksheet")
                {
                    ApplicationArea = Service;
                    Caption = '&Item Worksheet';
                    Image = ItemWorksheet;
                    RunObject = Page "Service Item Worksheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("Document No."),
                                  "Line No." = FIELD("Line No."),
                                  "Resource Filter" = FIELD("Resource Filter");
                    ToolTip = 'View or edit information about service items, such as repair status, fault comments and codes, and cost. In this window, you can update information on the items such as repair status and fault and resolution codes. You can also enter new service lines for resource hours, for the use of spare parts and for specific service costs.';
                }
            }
        }
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Service &Tasks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Tasks';
                    Ellipsis = true;
                    Image = ServiceTasks;
                    ToolTip = 'View information about service items on service orders, for example, repair status, response time and service shelf number.';

                    trigger OnAction()
                    begin
                        Clear(ServItemLine);
                        FilterGroup(2);
                        ServItemLine.SetView(GetView());
                        FilterGroup(0);
                        ServItemLine.SetRange("No. of Allocations");
                        ServItemLine.SetRange("No. of Active/Finished Allocs");

                        REPORT.Run(REPORT::"Service Tasks", true, true, ServItemLine);
                    end;
                }
                action("Service Item &Worksheet")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item &Worksheet';
                    Ellipsis = true;
                    Image = ServiceItemWorksheet;
                    ToolTip = 'Prepare to record service hours and spare parts used, repair status, fault comments, and cost.';

                    trigger OnAction()
                    begin
                        Clear(ServItemLine);
                        ServItemLine.SetRange("Document Type", "Document Type");
                        ServItemLine.SetRange("Document No.", "Document No.");
                        ServItemLine.SetRange("Line No.", "Line No.");
                        REPORT.Run(REPORT::"Service Item Worksheet", true, true, ServItemLine);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Document_Promoted"; "&Show Document")
                {
                }
                actionref("&Item Worksheet_Promoted"; "&Item Worksheet")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ServHeader.Get("Document Type", "Document No.");

        if not Cust.Get(ServHeader."Customer No.") then
            Clear(Cust);

        CalcFields("No. of Active/Finished Allocs");
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        SetAllFilters();

        if Rec.IsEmpty() then begin
            ServOrderFilter := '';
            SetServOrderFilter();
        end;
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RepairStatus: Record "Repair Status";
        Cust: Record Customer;
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        Res: Record Resource;
        ResourceGroup: Record "Resource Group";
        AllocationStatus: Option " ",Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        DocFilter: Option "Order",Quote,All;
        TempTextFilter: Text;
        Text000: Label 'There is no %1 within the filter.';
        TempAllocationStatus: Option " ",Nonactive,Active,Finished,Canceled,"Reallocation Needed";

    protected var
        RepairStatusFilter: Text;
        RespDateFilter: Text;
        ServOrderFilter: Text;
        ResourceFilter: Text;
        ResourceGroupFilter: Text;

    procedure SetAllFilters()
    begin
        SetRepStatFilter();
        SetRespDateFilter();
        SetDocFilter();
        SetServOrderFilter();
        SetResourceFilter();
        SetResourceGroupFilter();
        SetAllocationFilter();

        OnAfterSetAllFilters(Rec);
    end;

    procedure SetRepStatFilter()
    begin
        FilterGroup(2);
        SetFilter("Repair Status Code", RepairStatusFilter);
        RepairStatusFilter := GetFilter("Repair Status Code");
        FilterGroup(0);
    end;

    procedure SetRespDateFilter()
    var
        FilterTokens: Codeunit "Filter Tokens";
    begin
        FilterGroup(2);
        FilterTokens.MakeDateFilter(RespDateFilter);
        SetFilter("Response Date", RespDateFilter);
        RespDateFilter := GetFilter("Response Date");
        FilterGroup(0);
    end;

    procedure SetDocFilter()
    begin
        FilterGroup(2);
        case DocFilter of
            DocFilter::Order:
                SetRange("Document Type", "Document Type"::Order);
            DocFilter::Quote:
                SetRange("Document Type", "Document Type"::Quote);
            DocFilter::All:
                SetRange("Document Type");
        end;
        FilterGroup(0);
    end;

    procedure SetDocFilterHeader(var ServHeader: Record "Service Header")
    begin
        with ServHeader do begin
            FilterGroup(2);
            case DocFilter of
                DocFilter::Order:
                    SetRange("Document Type", "Document Type"::Order);
                DocFilter::Quote:
                    SetRange("Document Type", "Document Type"::Quote);
                DocFilter::All:
                    SetRange("Document Type");
            end;
            FilterGroup(0);
        end;
    end;

    procedure SetServOrderFilter()
    begin
        FilterGroup(2);
        SetFilter("Document No.", ServOrderFilter);
        ServOrderFilter := GetFilter("Document No.");
        FilterGroup(0);
    end;

    procedure SetResourceFilter()
    begin
        FilterGroup(2);
        if ResourceFilter <> '' then begin
            SetFilter("No. of Active/Finished Allocs", '>0');
            SetFilter("Resource Filter", ResourceFilter);
            ResourceFilter := GetFilter("Resource Filter");
        end else begin
            if ResourceGroupFilter = '' then
                SetRange("No. of Active/Finished Allocs");
            SetRange("Resource Filter");
        end;
        FilterGroup(0);
    end;

    procedure SetResourceGroupFilter()
    begin
        FilterGroup(2);
        if ResourceGroupFilter <> '' then begin
            SetFilter("No. of Active/Finished Allocs", '>0');
            SetFilter("Resource Group Filter", ResourceGroupFilter);
            ResourceGroupFilter := GetFilter("Resource Group Filter");
        end else begin
            if ResourceFilter = '' then
                SetRange("No. of Active/Finished Allocs");
            SetRange("Resource Group Filter");
        end;
        FilterGroup(0);
    end;

    procedure SetAllocationFilter()
    begin
        FilterGroup(2);
        case AllocationStatus of
            AllocationStatus::" ":
                begin
                    SetRange("Allocation Status Filter");
                    SetRange("No. of Allocations");
                end;
            AllocationStatus::Nonactive:
                begin
                    SetRange("Allocation Status Filter", "Allocation Status Filter"::Nonactive);
                    SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Active:
                begin
                    SetRange("Allocation Status Filter", "Allocation Status Filter"::Active);
                    SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Finished:
                begin
                    SetRange("Allocation Status Filter", "Allocation Status Filter"::Finished);
                    SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Canceled:
                begin
                    SetRange("Allocation Status Filter", "Allocation Status Filter"::Canceled);
                    SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::"Reallocation Needed":
                begin
                    SetRange("Allocation Status Filter", "Allocation Status Filter"::"Reallocation Needed");
                    SetFilter("No. of Allocations", '>0');
                end;
        end;
        FilterGroup(0);
    end;

    local procedure TestFilter(): Boolean
    begin
        if ServOrderFilter <> '' then begin
            FilterGroup(2);
            if GetRangeMin("Document No.") = GetRangeMax("Document No.") then
                if IsEmpty() then begin
                    FilterGroup(0);
                    exit(false);
                end;
            FilterGroup(0);
        end;
        exit(true);
    end;

    local procedure RepairStatusFilterOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure AllocationStatusOnAfterValidat()
    begin
        CurrPage.Update(false);
    end;

    local procedure DocFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ServOrderFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure RespDateFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceGroupFilterOnAfterVali()
    begin
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAllFilters(var ServiceItemLine: Record "Service Item Line")
    begin
    end;
}

