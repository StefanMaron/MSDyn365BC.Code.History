page 6005 "Resource Allocations"
{
    Caption = 'Resource Allocations';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Service Order Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of the document (Order or Quote) from which the allocation entry was created.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the service order associated with this entry.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the status of the entry, such as active, non-active, or cancelled.';
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the service item.';
                    Visible = true;
                }
                field("Service Item Serial No."; "Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item in this entry.';
                    Visible = false;
                }
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the service item line linked to this entry.';
                    Visible = false;
                }
                field("Service Item Description"; "Service Item Description")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies a description of the service item in this entry.';
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource allocated to the service task in this entry.';

                    trigger OnValidate()
                    begin
                        ResourceNoOnAfterValidate;
                    end;
                }
                field("Resource Group No."; "Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource group allocated to the service task in this entry.';
                    Visible = false;
                }
                field("Allocation Date"; "Allocation Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the resource allocation should start.';
                }
                field("Allocated Hours"; "Allocated Hours")
                {
                    ApplicationArea = Jobs;
                    DecimalPlaces = 1 : 2;
                    ToolTip = 'Specifies the hours allocated to the resource or resource group for the service task in this entry.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the time when you want the allocation to start.';
                    Visible = false;
                }
                field("Finishing Time"; "Finishing Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the time when you want the allocation to finish.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description for the service order allocation.';
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
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action(ResourceAvailability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Resource Availability';
                    Image = Calendar;
                    ToolTip = 'View the work calendar of the selected resource.';

                    trigger OnAction()
                    begin
                        Clear(ResAvailability);
                        ResAvailability.SetData(
                          "Document Type", "Document No.", "Service Item Line No.", "Entry No.");
                        if "Resource No." <> '' then begin
                            Res.Get("Resource No.");
                            ResAvailability.SetRecord(Res);
                        end;
                        ResAvailability.RunModal;
                    end;
                }
                action(ResGroupAvailability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Res. &Group Availability';
                    Image = Calendar;
                    ToolTip = 'View allocations per resource group, such as the entire capacity, the quantity allocated to jobs on order, the quantity available after quotes, the quantity assigned to jobs on quote, and the remaining capacity after all jobs on quote or order.';

                    trigger OnAction()
                    begin
                        Clear(ResGrAvailability);
                        ResGrAvailability.SetData("Document Type", "Document No.", "Entry No.");
                        if "Resource Group No." <> '' then begin
                            ResGr.Get("Resource Group No.");
                            ResGrAvailability.SetRecord(ResGr);
                        end;
                        ResGrAvailability.RunModal;
                    end;
                }
                action("Canceled Allocation &Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Canceled Allocation &Entries';
                    Image = CancelledEntries;
                    ToolTip = 'View the list of service order allocation entries that have been canceled.';

                    trigger OnAction()
                    begin
                        Clear(CanceledAllocEntries);
                        ServOrderAlloc.Reset();
                        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", Status);
                        ServOrderAlloc.SetRange("Document Type", "Document Type");
                        ServOrderAlloc.SetRange("Document No.", "Document No.");
                        ServOrderAlloc.SetFilter(Status, '%1', ServOrderAlloc.Status::Canceled);
                        CanceledAllocEntries.SetTableView(ServOrderAlloc);
                        CanceledAllocEntries.SetRecord(ServOrderAlloc);
                        CanceledAllocEntries.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Cancel Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Cancel Allocation';
                    Image = Cancel;
                    ToolTip = 'Remove the current allocation of the resource.';

                    trigger OnAction()
                    var
                        ServOrderAllocMgt: Codeunit ServAllocationManagement;
                    begin
                        Clear(ServOrderAllocMgt);
                        ServOrderAllocMgt.CancelAllocation(Rec);
                    end;
                }
                action("Allocate to &all Service Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Allocate to &all Service Items';
                    Image = Allocate;
                    ToolTip = 'Allocate the same resource, for example, a technician, or resource group to all the service items in a service order.';

                    trigger OnAction()
                    begin
                        Clear(ServOrderAllocMgt);
                        ServOrderAllocMgt.SplitAllocation(Rec);
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if "Service Item Line No." = 0 then begin
            ServItemLine.Reset();
            ServItemLine.SetRange("Document Type", "Document Type");
            ServItemLine.SetRange("Document No.", "Document No.");
            if ServItemLine.Count = 1 then begin
                ServItemLine.FindFirst;
                "Service Item Line No." := ServItemLine."Line No.";
            end;
        end;
    end;

    var
        ServItemLine: Record "Service Item Line";
        ServOrderAlloc: Record "Service Order Allocation";
        Res: Record Resource;
        ResGr: Record "Resource Group";
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        ResAvailability: Page "Res. Availability (Service)";
        ResGrAvailability: Page "Res.Gr. Availability (Service)";
        CanceledAllocEntries: Page "Cancelled Allocation Entries";

    local procedure ResourceNoOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

